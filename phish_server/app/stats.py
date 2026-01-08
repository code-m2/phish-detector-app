from fastapi import APIRouter, Depends
from sqlmodel import select, Session
from datetime import datetime, timedelta

from app.models import Detection
from app.db import get_session

router = APIRouter(
    prefix="/api/stats",
    tags=["Stats"]
)

# --------------------------------------------------
# DASHBOARD STATS (HOME PAGE)
# --------------------------------------------------
@router.get("/dashboard")
def dashboard_stats(session: Session = Depends(get_session)):
    detections = session.exec(select(Detection)).all()

    total = len(detections)
    phishing = sum(
        1 for d in detections
        if d.prediction and d.prediction.lower() == "phishing"
    )

    return {
        "total": total,
        "phishing": phishing
    }


# --------------------------------------------------
# DAILY STATS (BAR / LINE CHART)
# --------------------------------------------------
@router.get("/daily")
def daily_stats(
    days: int = 7,
    session: Session = Depends(get_session)
):
    today = datetime.utcnow().date()
    result = []

    for i in range(days):
        day = today - timedelta(days=i)
        next_day = day + timedelta(days=1)

        phishing = session.exec(
            select(Detection).where(
                Detection.prediction == "phishing",
                Detection.timestamp >= day,
                Detection.timestamp < next_day,
            )
        ).all()

        legit = session.exec(
            select(Detection).where(
                Detection.prediction == "legitimate",
                Detection.timestamp >= day,
                Detection.timestamp < next_day,
            )
        ).all()

        result.append({
            "date": day.isoformat(),
            "phishing": len(phishing),
            "legitimate": len(legit),
        })

    return {"daily": list(reversed(result))}


# --------------------------------------------------
# TODAY STATS (OPTIONAL)
# --------------------------------------------------
@router.get("/today")
def today_stats(session: Session = Depends(get_session)):
    today = datetime.utcnow().date()

    phishing = session.exec(
        select(Detection).where(
            Detection.prediction == "phishing",
            Detection.timestamp >= today
        )
    ).all()

    legit = session.exec(
        select(Detection).where(
            Detection.prediction == "legitimate",
            Detection.timestamp >= today
        )
    ).all()

    return {
        "phishing": len(phishing),
        "legitimate": len(legit)
    }
