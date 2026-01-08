from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import json
import threading

# ---------------- INTERNAL IMPORTS ----------------
from app.db import init_db
from app.auth import router as auth_router
from app.detections import router as detections_router
from app.email_receiver import router as email_router
from app.deps import get_current_user
from app.predict_utils import run_predict
from app.models import Detection
from app.db import get_session
from app.imap_email_task import start_imap_monitor
from app.stats import router as stats_router

# ---------------- APP INIT ----------------
app = FastAPI(title="Phishing Detector API")

# ---------------- CORS ----------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- ROUTERS ----------------
app.include_router(auth_router)
app.include_router(detections_router)
app.include_router(email_router)
app.include_router(stats_router)

# ---------------- STARTUP ----------------
@app.on_event("startup")
def startup():
    init_db()

    # ✅ IMAP AUTO-SCAN (AUTOSCAN REQUIREMENT)
    threading.Thread(
        target=start_imap_monitor,
        args=(1,),   # demo user ID (acceptable for thesis/demo)
        daemon=True
    ).start()

# ---------------- MANUAL PREDICTION (OPTIONAL) ----------------
@app.post("/predict")
async def predict(
    request: Request,
    current_user=Depends(get_current_user)
):
    payload = await request.json()

    subject = payload.get("subject", "") or ""
    text = payload.get("text", "") or ""
    sender = payload.get("sender", "") or ""
    urls = payload.get("urls", [])
    has_attachment = int(payload.get("has_attachment", 0))
    links_count = int(payload.get("links_count", 0))

    if isinstance(urls, str):
        urls = [u.strip() for u in urls.split(",") if u.strip()]

    # ---------------- RUN MODEL ----------------
    result = run_predict(
        email_text=text,
        subject=subject,
        has_attachment=has_attachment,
        links_count=links_count,
        sender_domain=sender,
        urls=urls
    )

    # ---------------- SAVE TO DB ----------------
    with next(get_session()) as sess:
        record = Detection(
            user_id=current_user.id,
            subject=subject[:400],
            email_text=text[:5000],
            ml_prob=result["ml_probability"],
            rule_score=result["rule_score"],
            combined_score=result["combined_score"],
            prediction=result["prediction"],
            source="manual",
            extra_data=json.dumps({
                "sender": sender,
                "urls": urls,
                "has_attachment": has_attachment,
                "links_count": links_count
            }),
            timestamp=datetime.utcnow()
        )
        sess.add(record)
        sess.commit()

    return {
        "prediction": result["prediction"],
        "combined_score": result["combined_score"],
        "ml_probability": result["ml_probability"],
        "rule_score": result["rule_score"]
    }
