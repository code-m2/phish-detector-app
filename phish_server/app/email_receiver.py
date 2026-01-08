# app/email_receiver.py

from fastapi import APIRouter, Depends
from datetime import datetime
from sqlmodel import Session

from app.predict_utils import run_predict
from app.db import get_session
from app.models import Detection

router = APIRouter(prefix="/email", tags=["email"])


@router.post("/incoming")
def incoming_email(
    payload: dict,
    session: Session = Depends(get_session)
):
    subject = payload.get("subject", "")
    body = payload.get("body", "")
    sender = payload.get("sender", "")
    urls = payload.get("urls", [])
    has_attachment = int(payload.get("has_attachment", 0))
    links_count = int(payload.get("links_count", 0))

    result = run_predict(
        email_text=body,
        subject=subject,
        sender_domain=sender,
        urls=urls,
        has_attachment=has_attachment,
        links_count=links_count
    )

    detection = Detection(
        subject=subject,
        email_text=body,
        prediction=result["prediction"],
        ml_prob=result["ml_probability"],
        rule_score=result["rule_score"],
        combined_score=result["combined_score"],
        source="auto",
        timestamp=datetime.utcnow()
    )

    session.add(detection)
    session.commit()

    return {"status": "auto scanned", "prediction": result["prediction"]}
