import pandas as pd
import joblib
from scipy.sparse import hstack, csr_matrix
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.utils import resample
from app.text_utils import clean_text

# Load datasets
df_real = pd.read_csv("data/merged_phishing_dataset.csv")
df_synth = pd.read_csv("data/synthetic_phishing.csv")

df = pd.concat([df_real, df_synth], ignore_index=True)
df = df.dropna(subset=["email_text"])

# Balance
phish = df[df.label == "phishing"]
legit = df[df.label == "legitimate"]

if len(phish) > len(legit):
    legit = resample(legit, replace=True, n_samples=len(phish))
else:
    phish = resample(phish, replace=True, n_samples=len(legit))

df = pd.concat([phish, legit]).sample(frac=1)

# Clean text
df["clean_text"] = df["email_text"].apply(clean_text)

# Metadata
df["has_attachment"] = df.email_text.str.contains("attach|docx|pdf").astype(int)
df["links_count"] = df.email_text.str.count("URL")
df["urgent_keywords"] = df.email_text.str.contains("urgent|immediately|24 hours").astype(int)

X_text = df["clean_text"]
X_meta = df[["has_attachment", "links_count", "urgent_keywords"]]
y = df["label"]

# Vectorize
vectorizer = TfidfVectorizer(max_features=6000, ngram_range=(1,2))
X_vec = vectorizer.fit_transform(X_text)

# Scale metadata
scaler = StandardScaler()
X_meta_scaled = scaler.fit_transform(X_meta)
X_meta_sparse = csr_matrix(X_meta_scaled)

X_final = hstack([X_vec, X_meta_sparse])

# Train model
model = LogisticRegression(
    max_iter=2000,
    class_weight="balanced",
    solver="liblinear"
)
model.fit(X_final, y)

joblib.dump(model, "app/model.pkl")
joblib.dump(vectorizer, "app/vectorizer.pkl")
joblib.dump(scaler, "app/scaler.pkl")

print("✅ Model trained & saved")
