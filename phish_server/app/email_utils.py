# app/email_utils.py
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

EMAIL_ADDRESS = "khan.m.bscs@gmail.com"
EMAIL_PASSWORD = "uwto tibq wogh ofeu"   # from Google App Passwords

def send_otp_email(recipient: str, otp: str):
    """
    Sends a 6-digit OTP code to the user.
    """

    subject = "Your Verification Code"
    body = f"""
Your verification code is:

    {otp}

This code will expire in 10 minutes.
If you did not request this, ignore this email.
"""

    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = EMAIL_ADDRESS
    msg["To"] = recipient

    # Gmail SMTP server (TLS)
    with smtplib.SMTP("smtp.gmail.com", 587) as smtp:
        smtp.starttls()
        smtp.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        smtp.send_message(msg)

    print(f"[EMAIL] Sent OTP to {recipient}")
