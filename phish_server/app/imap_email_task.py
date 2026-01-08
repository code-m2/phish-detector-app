import time
from imapclient import IMAPClient
import pyzmail
from datetime import datetime
from sqlmodel import Session

from app.db import engine
from app.models import Detection
from app.predict_utils import run_predict

GMAIL_HOST = "imap.gmail.com"
GMAIL_USER = "mupkhan2@gmail.com"
GMAIL_APP_PASSWORD = "ypvs cynh fthp mngc"


def start_imap_monitor(user_id: int | None = None):
    while True:
        try:
            with IMAPClient(GMAIL_HOST, ssl=True) as server:
                server.login(GMAIL_USER, GMAIL_APP_PASSWORD)
                server.select_folder("INBOX")

                messages = server.search(["UNSEEN"])

                if not messages:
                    time.sleep(15)
                    continue

                with Session(engine) as session:
                    for uid in messages:
                        raw = server.fetch([uid], ["RFC822"])[uid][b"RFC822"]
                        msg = pyzmail.PyzMessage.factory(raw)

                        subject = msg.get_subject() or ""
                        body = ""

                        if msg.text_part:
                            body = msg.text_part.get_payload().decode(
                                msg.text_part.charset or "utf-8",
                                errors="ignore"
                            )

                        result = run_predict(
                            email_text=body,
                            subject=subject,
                            links_count=body.lower().count("http"),
                            has_attachment=1 if len(msg.mailparts) > 1 else 0,
                        )

                        detection = Detection(
                            user_id=user_id,           # None = global
                            subject=subject[:400],
                            email_text=body[:5000],
                            prediction=result["prediction"],
                            ml_prob=result["ml_probability"],
                            rule_score=result["rule_score"],
                            combined_score=result["combined_score"],
                            source="auto",
                            timestamp=datetime.utcnow(),
                        )

                        session.add(detection)
                        server.add_flags(uid, [b"\\Seen"])

                    session.commit()

        except Exception as e:
            print("IMAP ERROR:", e)

        time.sleep(15)
