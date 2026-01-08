from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from sqlmodel import select, Session
import random

from app.db import get_session
from app.models import User
from app.auth_utils import hash_password, verify_password, create_access_token
from app.email_utils import send_otp_email

router = APIRouter(prefix="/auth", tags=["auth"])


# ---------------- REQUEST MODELS ----------------

class SignupIn(BaseModel):
    name: str
    email: EmailStr
    password: str

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class VerifyCodeIn(BaseModel):
    email: EmailStr
    code: str

class ResetPasswordIn(BaseModel):
    email: EmailStr

class SetPasswordIn(BaseModel):
    email: EmailStr
    new_password: str

class DeleteUserIn(BaseModel):
    email: EmailStr


# ---------------- HELPERS ----------------

def generate_otp():
    return str(random.randint(100000, 999999))


# ---------------- SIGNUP ----------------

@router.post("/signup")
async def signup(
    payload: SignupIn,
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    existing = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if existing:
        raise HTTPException(400, "Email already registered")

    user = User(
        name=payload.name,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        is_verified=False
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    otp = generate_otp()
    user.verification_code = otp
    user.verification_expiry = datetime.utcnow() + timedelta(minutes=10)
    session.add(user)
    session.commit()

    background_tasks.add_task(send_otp_email, user.email, otp)
    return {"status": "ok", "message": "Verification code sent"}


# ---------------- VERIFY SIGNUP ----------------

@router.post("/verify_code")
def verify_code(
    payload: VerifyCodeIn,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if not user:
        raise HTTPException(404, "User not found")

    if user.verification_code != payload.code:
        raise HTTPException(400, "Invalid code")

    if user.verification_expiry < datetime.utcnow():
        raise HTTPException(400, "Code expired")

    user.is_verified = True
    user.verification_code = None
    user.verification_expiry = None
    session.add(user)
    session.commit()

    return {"status": "ok", "message": "Email verified"}


# ---------------- LOGIN ----------------

@router.post("/login")
def login(
    payload: LoginIn,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(400, "Invalid credentials")

    if not user.is_verified:
        raise HTTPException(403, "Email not verified")

    token = create_access_token(user.email)
    return {"access_token": token, "token_type": "bearer"}


# ---------------- FORGOT PASSWORD ----------------

@router.post("/forgot_password")
def forgot_password(
    payload: ResetPasswordIn,
    background_tasks: BackgroundTasks,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if not user:
        raise HTTPException(404, "User not found")

    otp = generate_otp()
    user.reset_code = otp
    user.reset_expiry = datetime.utcnow() + timedelta(minutes=10)
    session.add(user)
    session.commit()

    background_tasks.add_task(send_otp_email, user.email, otp)
    return {"status": "ok", "message": "Reset code sent"}


# ---------------- VERIFY RESET ----------------

@router.post("/verify_reset_code")
def verify_reset_code(
    payload: VerifyCodeIn,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if not user:
        raise HTTPException(404, "User not found")

    if user.reset_code != payload.code:
        raise HTTPException(400, "Invalid code")

    if user.reset_expiry < datetime.utcnow():
        raise HTTPException(400, "Code expired")

    return {"status": "ok"}


# ---------------- SET NEW PASSWORD ----------------

@router.post("/set_new_password")
def set_new_password(
    payload: SetPasswordIn,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if not user:
        raise HTTPException(404, "User not found")

    user.password_hash = hash_password(payload.new_password)
    user.reset_code = None
    user.reset_expiry = None
    session.add(user)
    session.commit()

    return {"status": "ok", "message": "Password updated"}


# ---------------- DELETE USER ----------------

@router.delete("/delete_user")
def delete_user(
    payload: DeleteUserIn,
    session: Session = Depends(get_session)
):
    user = session.exec(
        select(User).where(User.email == payload.email.lower())
    ).first()
    if not user:
        raise HTTPException(404, "User not found")

    session.delete(user)
    session.commit()
    return {"status": "ok"}
