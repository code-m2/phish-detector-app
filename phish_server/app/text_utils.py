import re
import pandas as pd

def clean_text(text: str) -> str:
    if not text or pd.isna(text):
        return ""

    text = text.lower()
    text = re.sub(r"http\S+|www\S+|https\S+", " URL ", text)
    text = re.sub(r"\S+@\S+", " EMAIL ", text)

    text = text.replace("0", "o").replace("1", "l") \
               .replace("3", "e").replace("5", "s") \
               .replace("7", "t")

    text = re.sub(r"[^a-z\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text
