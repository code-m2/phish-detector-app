import asyncio
from app.email_utils import send_verification_email

# Replace this with your real email to test
email = "khan.m.bscs@gmail.com"

asyncio.run(send_verification_email(email, "dummy-token-123"))
