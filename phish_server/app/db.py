from sqlmodel import SQLModel, create_engine, Session
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import select
from app.models import User
from app.auth_utils import decode_token

DATABASE_URL = "sqlite:///database.db"

engine = create_engine(DATABASE_URL, echo=False)


# Initialize DB tables
def init_db():
    SQLModel.metadata.create_all(engine)


# FIX: Return actual Session object (NOT a generator)
def get_session():
    return Session(engine)


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


# Current authenticated user
def get_current_user(
    token: str = Depends(oauth2_scheme),
):
    session = get_session()

    try:
        payload = decode_token(token)
        email = payload.get("sub")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = session.exec(select(User).where(User.email == email)).first()

    session.close()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user
