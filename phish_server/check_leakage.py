import os
import re
import random
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

DATA_PATH = "data/final_clean_nodup_nosim.csv"
RANDOM_STATE = 42

def clean_text(text):
    text = str(text).lower()
    text = re.sub(r"http\S+|www\S+|https\S+", " ", text)
    text = re.sub(r"\S+@\S+", " ", text)
    text = text.replace("0", "o").replace("1", "l").replace("3", "e").replace("5", "s").replace("7", "t")
    text = re.sub(r"[^a-z\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text

def main():
    print("Checking working directory:", os.getcwd())
    if not os.path.exists(DATA_PATH):
        print(f"ERROR: dataset not found at '{DATA_PATH}'. Adjust DATA_PATH or run from project root.")
        return

    print("Loading dataset...")
    df = pd.read_csv(DATA_PATH)
    print("Rows:", len(df), "Columns:", df.columns.tolist())

    # Combine and clean
    df["text"] = (df.get("subject", "").fillna("") + " " + df.get("email_text", "").fillna("")).apply(clean_text)

    # 1) Exact duplicate rows (full row duplicates)
    full_dup_count = df.duplicated().sum()
    print(f"\n1) Exact full-row duplicates in dataset: {full_dup_count}")

    # 2) Exact duplicate texts (subject+body)
    text_dup_count = df["text"].duplicated().sum()
    print(f"2) Exact duplicate 'text' (subject+body) entries: {text_dup_count}")

    # If duplicates exist, show example
    if text_dup_count > 0:
        dup_texts = df[df["text"].duplicated(keep=False)]["text"].unique()[:3]
        print("\n Example duplicate texts (first 3):")
        for t in dup_texts:
            print(" -", t[:200].replace("\n"," "))

    # Optionally drop duplicates for a leakage check run
    df_nodup = df.drop_duplicates(subset=["text"]).reset_index(drop=True)
    dropped = len(df) - len(df_nodup)
    print(f"\nDropped {dropped} duplicate text rows for leakage-safe split. Remaining rows: {len(df_nodup)}")

    # 3) Split same as training
    X = df_nodup["text"]
    y = df_nodup["label"]
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y
    )

    # 4) Exact overlap between train/test
    train_set = set(X_train)
    test_set = set(X_test)
    overlap = train_set.intersection(test_set)
    print(f"\n3) Exact overlap between train and test: {len(overlap)} items")

    # 5) Near-duplicate detection (sampleed) - cosine similarity on TF-IDF
    # Limit sample size to keep memory small
    sample_size = 1000
    n_train_sample = min(sample_size, len(X_train))
    n_test_sample = min(sample_size, len(X_test))

    print(f"\n4) Running near-duplicate check with up to {n_train_sample} train x {n_test_sample} test samples...")

    # Sample deterministically
    train_idxs = np.random.RandomState(RANDOM_STATE).choice(len(X_train), n_train_sample, replace=False)
    test_idxs = np.random.RandomState(RANDOM_STATE+1).choice(len(X_test), n_test_sample, replace=False)

    X_train_sample = X_train.iloc[train_idxs].tolist()
    X_test_sample = X_test.iloc[test_idxs].tolist()

    # Vectorize these samples
    vectorizer = TfidfVectorizer(ngram_range=(1,2), max_features=5000)
    combined = X_train_sample + X_test_sample
    tfidf = vectorizer.fit_transform(combined)

    tfidf_train = tfidf[:n_train_sample]
    tfidf_test = tfidf[n_train_sample:]

    # Compute cosine similarities in chunks to avoid huge memory usage
    # We'll report pairs with similarity >= 0.95
    threshold = 0.95
    near_dup_pairs = 0
    # compute full matrix if small; else chunk test side
    sim_matrix = cosine_similarity(tfidf_train, tfidf_test)
    # Count pairs above threshold
    near_dup_pairs = np.sum(sim_matrix >= threshold)
    print(f"Near-duplicate pairs with cosine >= {threshold}: {int(near_dup_pairs)}")

    if near_dup_pairs > 0:
        # show up to 5 example pairs
        print("\nExample near-duplicate pairs (showing up to 5):")
        pairs_shown = 0
        train_idx_flat, test_idx_flat = np.where(sim_matrix >= threshold)
        for ti, tj in zip(train_idx_flat, test_idx_flat):
            print("----")
            print("TRAIN:", X_train_sample[ti][:300])
            print("TEST :", X_test_sample[tj][:300])
            pairs_shown += 1
            if pairs_shown >= 5:
                break

    print("\nDone. If you see any duplicates or near-duplicates, consider deduplicating before retraining.")
    print("Tip: run this script from project root so DATA_PATH='data/merged_dataset_bank_augmented.csv' works.")

if __name__ == "__main__":
    main()
