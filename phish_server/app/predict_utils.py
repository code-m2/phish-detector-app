import joblib
import numpy as np
import pandas as pd
from scipy.sparse import hstack, csr_matrix
from urllib.parse import urlparse
from app.text_utils import clean_text

model = joblib.load("app/model.pkl")
vectorizer = joblib.load("app/vectorizer.pkl")
scaler = joblib.load("app/scaler.pkl")


def run_predict(
    email_text: str,
    subject: str = "",
    has_attachment: int = 0,
    links_count: int = 0,
    sender_domain: str = "",
    urls=None
):
    if urls is None:
        urls = []

    text = email_text.lower()
    raw = clean_text(subject + " " + email_text)

    # -----------------------------
    # ML FEATURE PIPELINE (SECONDARY)
    # -----------------------------
    X_vec = vectorizer.transform([raw])

    urgent = int(any(k in text for k in [
        "urgent", "immediately", "asap", "now", "within 24 hours"
    ]))

    # FIX: Use DataFrame with feature names (removes sklearn warning)
    meta_df = pd.DataFrame([{
        "has_attachment": has_attachment,
        "links_count": links_count,
        "urgent_keywords": urgent
    }])

    meta_scaled = scaler.transform(meta_df)
    meta_sparse = csr_matrix(meta_scaled)

    X_final = hstack([X_vec, meta_sparse])
    ml_prob = float(model.predict_proba(X_final)[0][1])

    # -----------------------------
    # RULE-BASED DETECTION (PRIMARY)
    # -----------------------------
    rule_score = 0.0

    # 🚨 MALICIOUS ATTACHMENTS
    if has_attachment:
        if "enable editing" in text or "macro" in text or ".docx" in text:
            rule_score = max(rule_score, 0.9)
        else:
            rule_score = max(rule_score, 0.6)

    # 🚨 URGENCY
    if any(k in text for k in ["urgent", "immediately", "within 24 hours"]):
        rule_score = max(rule_score, 0.7)

    # 🚨 BRAND / BANK IMPERSONATION
    if any(k in text for k in ["bank", "paypal", "amazon", "account", "verify"]):
        rule_score = max(rule_score, 0.7)

    # 🚨 REWARD / INCENTIVE SOCIAL ENGINEERING
    if any(k in text for k in [
        "gift card",
        "giftcard",
        "you qualify",
        "won",
        "winner",
        "prize",
        "free",
        "reward",
        "giveaway"
    ]):
        rule_score = max(rule_score, 0.75)

    # 🚨 PAYMENT / CEO FRAUD
    if any(k in text for k in ["invoice", "wire transfer", "payment required"]):
        rule_score = max(rule_score, 0.8)

    # 🚨 CREDENTIAL HARVESTING
    if any(k in text for k in ["password", "credentials", "login"]):
        rule_score = max(rule_score, 0.85)

    # 🚨 SUSPICIOUS LINKS
    for u in urls:
        domain = urlparse(u).netloc.lower()
        if any(s in domain for s in ["bit.ly", "tinyurl", "t.co"]):
            rule_score = max(rule_score, 0.85)
        if "mybank" in text and "mybank.com" not in domain:
            rule_score = max(rule_score, 0.9)

    # -----------------------------
    # SAFE CONTEXT REDUCERS
    # -----------------------------
    safe_reducer = 0.0

    if "we will never ask for your password" in text:
        safe_reducer += 0.35

    if "official website" in text or "log in to your official" in text:
        safe_reducer += 0.25

    if sender_domain.endswith(".com") and any(b in sender_domain for b in ["bank", "amazon", "paypal"]):
        safe_reducer += 0.20

    # -----------------------------
    # FINAL SCORE (BALANCED)
    # -----------------------------
    combined = (ml_prob * 0.55) + (rule_score * 0.45) - safe_reducer
    combined = max(0.0, min(combined, 1.0))

    prediction = "phishing" if combined >= 0.65 else "legitimate"

    return {
        "prediction": prediction,
        "ml_probability": round(ml_prob, 3),
        "rule_score": round(rule_score, 3),
        "combined_score": round(combined, 3),
    }
