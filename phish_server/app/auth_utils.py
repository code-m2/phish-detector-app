# app/auth_utils.py
from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta
from typing import Optional

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

JWT_SECRET = "replace-this-with-a-long-random-secret"
JWT_ALGO = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24
VERIFY_TOKEN_EXPIRE_MINUTES = 60 * 24
BCRYPT_MAX_BYTES = 72


def _truncate_to_bcrypt_limit(password: str) -> str:
    if password is None:
        return ""
    b = password.encode("utf-8")
    if len(b) <= BCRYPT_MAX_BYTES:
        return password
    return b[:BCRYPT_MAX_BYTES].decode("utf-8", errors="ignore")


def hash_password(password: str) -> str:
    return pwd_ctx.hash(_truncate_to_bcrypt_limit(password))


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_ctx.verify(_truncate_to_bcrypt_limit(plain), hashed)


def create_access_token(subject: str, expires_minutes: Optional[int] = None) -> str:
    expire = datetime.utcnow() + timedelta(
        minutes=expires_minutes or ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {"sub": str(subject), "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGO)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGO])
    except JWTError:
        return {}


def create_verify_token(email: str, expires_minutes: Optional[int] = None) -> str:
    expire = datetime.utcnow() + timedelta(
        minutes=expires_minutes or VERIFY_TOKEN_EXPIRE_MINUTES
    )
    payload = {"sub": email, "exp": expire, "type": "verify"}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGO)
