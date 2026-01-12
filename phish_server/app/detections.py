# detection.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlmodel import select, Session
from datetime import datetime, timedelta, date
from typing import List
import json

from app.db import get_session
from app.models import Detection, Notification
from app.predict_utils import run_predict
from app.deps import get_current_user
from app.email_utils import send_otp_email

router = APIRouter(prefix="/api", tags=["detections"])


# -------------------------------------------------
# HELPERS
# -------------------------------------------------
def generate_suggestions(det: dict) -> List[str]:
    txt = det.get("email_text", "").lower()
    s: List[str] = []

    # Only generate actionable suggestions for phishing
    if det.get("prediction") == "phishing":
        s.append("Do not click links or open attachments.")
        s.append("Verify the sender via the organization’s official website or phone number.")

        if "urgent" in txt or "immediately" in txt or "asap" in txt:
            s.append("Urgency is a common phishing tactic—slow down and verify first.")

        if "password" in txt or "login" in txt or "credentials" in txt:
            s.append("Never enter credentials from email links—type the official site manually.")

        if det.get("links_count", 0) > 0:
            s.append("Hover or inspect links for mismatched domains before clicking.")

        return s

    # If legitimate, return empty (so UI won’t show the suggestions card)
    return []


# -------------------------------------------------
# ANALYZE + SAVE DETECTION
# -------------------------------------------------
@router.post("/analyze_and_log")
def analyze_and_log(
    payload: dict,
    background_tasks: BackgroundTasks,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    text = (payload.get("text") or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")

    result = run_predict(
        email_text=text,
        subject=payload.get("subject", "") or "",
        has_attachment=int(payload.get("has_attachment", 0) or 0),
        links_count=int(payload.get("links_count", 0) or 0),
        sender_domain=payload.get("sender_domain", "") or "",
        urls=payload.get("urls", []) or [],
    )

    det = Detection(
        user_id=user.id,
        subject=payload.get("subject"),
        email_text=text,
        ml_prob=result["ml_probability"],
        rule_score=result["rule_score"],
        combined_score=result["combined_score"],
        prediction=result["prediction"],
        source=payload.get("source", "manual"),
        timestamp=datetime.utcnow(),
        extra_data=json.dumps({**payload, **result}),
    )

    session.add(det)
    session.commit()
    session.refresh(det)

    # Notification + email only if phishing
    if det.prediction == "phishing":
        note = Notification(
            user_id=user.id,
            detection_id=det.id,
            message=f"Phishing detected: {det.subject or 'No subject'}",
            read=False,
            created_at=datetime.utcnow(),
        )
        session.add(note)
        session.commit()

        background_tasks.add_task(
            send_otp_email,
            user.email,
            f"⚠ Phishing detected\nSubject: {det.subject}",
        )

    suggestions = generate_suggestions(
        {
            "email_text": text,
            "prediction": det.prediction,
            "links_count": int(payload.get("links_count", 0) or 0),
        }
    )

    # IMPORTANT: Return in the shape Flutter expects: body.detection
    return {
        "status": "ok",
        "detection": {
            "id": det.id,
            "prediction": det.prediction,
            "combined_score": det.combined_score,
            "suggestions": suggestions,
        },
    }


# -------------------------------------------------
# DETECTION HISTORY
# -------------------------------------------------
@router.get("/detections")
def list_detections(
    limit: int = 50,
    offset: int = 0,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    stmt = (
        select(Detection)
        .where(Detection.user_id == user.id)
        .order_by(Detection.timestamp.desc())
        .offset(offset)
        .limit(limit)
    )
    return {"detections": session.exec(stmt).all()}


# -------------------------------------------------
# NOTIFICATIONS
# -------------------------------------------------
@router.get("/notifications")
def get_notifications(
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    stmt = (
        select(Notification)
        .where(Notification.user_id == user.id)
        .order_by(Notification.created_at.desc())
    )
    return {"notifications": session.exec(stmt).all()}


@router.post("/notifications/mark_read")
def mark_read(
    notification_id: int,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    n = session.exec(
        select(Notification)
        .where(Notification.id == notification_id)
        .where(Notification.user_id == user.id)
    ).first()

    if not n:
        raise HTTPException(status_code=404, detail="Notification not found")

    n.read = True
    session.add(n)
    session.commit()
    return {"status": "ok"}


# -------------------------------------------------
# STATS: DAILY
# -------------------------------------------------
@router.get("/stats/daily")
def stats_daily(
    days: int = 30,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    start = datetime.utcnow() - timedelta(days=days - 1)

    rows = session.exec(
        select(Detection)
        .where(
            Detection.user_id == user.id,
            Detection.timestamp >= start,
        )
    ).all()

    counts = {}
    for r in rows:
        d = r.timestamp.date().isoformat()
        counts.setdefault(d, {"phishing": 0, "legitimate": 0})
        counts[d][r.prediction] += 1

    result = []
    for i in range(days):
        d = (date.today() - timedelta(days=days - 1 - i)).isoformat()
        result.append(
            {
                "date": d,
                "phishing": counts.get(d, {}).get("phishing", 0),
                "legitimate": counts.get(d, {}).get("legitimate", 0),
            }
        )

    return {"daily": result}


# -------------------------------------------------
# STATS: PROGRESS
# -------------------------------------------------
@router.get("/stats/progress")
def stats_progress(
    days: int = 7,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    today = date.today()
    start = today - timedelta(days=days - 1)
    prev_start = start - timedelta(days=days)
    prev_end = start - timedelta(days=1)

    def count_between(s, e):
        return session.exec(
            select(Detection).where(
                Detection.user_id == user.id,
                Detection.timestamp >= datetime.combine(s, datetime.min.time()),
                Detection.timestamp <= datetime.combine(e, datetime.max.time()),
            )
        ).count()

    current = count_between(start, today)
    previous = count_between(prev_start, prev_end)

    if previous == 0:
        pct_change = 100.0 if current > 0 else 0.0
    else:
        pct_change = ((current - previous) / previous) * 100.0

    return {"current": current, "previous": previous, "pct_change": round(pct_change, 2)}


# -------------------------------------------------
# AUTO-DETECT SETTING (IMAP AUTOSCAN)
# -------------------------------------------------
@router.post("/settings/autodetect")
def set_autodetect(
    enabled: bool,
    user=Depends(get_current_user),
    session: Session = Depends(get_session),
):
    data = json.loads(user.extra_data or "{}")
    data["autodetect"] = bool(enabled)
    user.extra_data = json.dumps(data)

    session.add(user)
    session.commit()

    return {"status": "ok", "autodetect": enabled}
