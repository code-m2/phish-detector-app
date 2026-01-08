# app/deps.py
from fastapi import Depends, HTTPException, Header
from sqlmodel import Session, select

from app.auth_utils import decode_token
from app.db import get_session
from app.models import User


def get_current_user(
    authorization: str = Header(None),
    session: Session = Depends(get_session)
):
    if not authorization:
        raise HTTPException(401, "Missing Authorization header")

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(401, "Invalid Authorization header")

    data = decode_token(token)
    if not data:
        raise HTTPException(401, "Invalid or expired token")

    sub = data.get("sub")
    if not sub:
        raise HTTPException(401, "Invalid token payload")

    stmt = select(User).where(User.email == sub.lower())
    user = session.exec(stmt).first()

    if not user:
        raise HTTPException(401, "User not found")

    return user
