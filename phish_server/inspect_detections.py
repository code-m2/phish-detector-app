# inspect_detections.py
from sqlmodel import Session, select
from app.db import engine
from app.models import Detection

with Session(engine) as session:
    rows = session.exec(
        select(Detection)
        .order_by(Detection.timestamp.desc())
        .limit(10)
    ).all()

    for r in rows:
        print(r.id, r.user_id, r.prediction, r.combined_score, r.timestamp)
