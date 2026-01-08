#models.py
from sqlmodel import SQLModel, Field, Column
from typing import Optional
from datetime import datetime
from sqlalchemy import String, Boolean, DateTime


# -------------------------
# USER TABLE
# -------------------------
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: Optional[str] = Field(default=None)
    email: str
    password_hash: Optional[str] = Field(default=None)

    # ----- Signup verification -----
    verification_code: Optional[str] = Field(
        default=None, sa_column=Column(String(6))
    )
    verification_expiry: Optional[datetime] = Field(
        default=None, sa_column=Column(DateTime)
    )
    is_verified: bool = Field(
        default=False, sa_column=Column(Boolean, default=False)
    )

    # ----- Forgot-password reset -----
    reset_code: Optional[str] = Field(
        default=None, sa_column=Column(String(6))
    )
    reset_expiry: Optional[datetime] = Field(
        default=None, sa_column=Column(DateTime)
    )

    # ----- User settings (autodetect, theme, etc.) -----
    extra_data: Optional[str] = Field(default=None)

    created_at: datetime = Field(default_factory=datetime.utcnow)


# -------------------------
# DETECTION LOG TABLE
# -------------------------
class Detection(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    subject: Optional[str] = None
    email_text: Optional[str] = None
    ml_prob: Optional[float] = None
    rule_score: Optional[float] = None
    combined_score: Optional[float] = None
    prediction: Optional[str] = None
    source: Optional[str] = "manual"

    # store as JSON string for extra info
    extra_data: Optional[str] = Field(default=None)


# -------------------------
# NOTIFICATIONS TABLE
# -------------------------
class Notification(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: Optional[int] = None
    detection_id: Optional[int] = None
    message: Optional[str] = None
    read: bool = Field(default=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)


# -------------------------
# MODEL VERSION TABLE
# -------------------------
class ModelVersion(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: Optional[str] = None
    version: Optional[str] = None
    metrics: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
