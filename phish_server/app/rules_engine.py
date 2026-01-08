import re

# -----------------------------
# Keyword Sets
# -----------------------------

PHISH_KEYWORDS = [
    "verify", "urgent", "suspend", "locked", "confirm",
    "click here", "act now", "limited time", "expires",
    "wire transfer", "gift card", "enable editing"
]

CREDENTIAL_KEYWORDS = [
    "password", "credentials", "ssn", "social security",
    "card number", "cvv", "account number"
]

SAFE_PHRASES = [
    "we will never ask for your password",
    "do not share your password",
    "log in to your official",
    "contact customer support directly"
]

INTERNAL_SENDERS = [
    "hr@", "payroll@", "intranet"
]

# -----------------------------
# Core Rule Engine
# -----------------------------

def rule_score(email_text: str, subject: str = "") -> float:
    text = f"{subject} {email_text}".lower()
    score = 0.0

    # -------------------------
    # RISK BOOSTERS
    # -------------------------

    for kw in PHISH_KEYWORDS:
        if kw in text:
            score += 0.10

    for kw in CREDENTIAL_KEYWORDS:
        if kw in text:
            score += 0.20

    # Link present
    if re.search(r"http[s]?://", text):
        score += 0.15

    # Attachment mention
    if "attached" in text or "attachment" in text:
        score += 0.10

    # -------------------------
    # SAFE REDUCERS (CRITICAL)
    # -------------------------

    for phrase in SAFE_PHRASES:
        if phrase in text:
            score -= 0.30

    for sender in INTERNAL_SENDERS:
        if sender in text:
            score -= 0.25

    # No urgency language
    if not any(x in text for x in ["urgent", "immediately", "expires", "24 hours"]):
        score -= 0.10

    # -------------------------
    # Clamp score
    # -------------------------

    return max(0.0, min(score, 1.0))
