import smtplib
from email.message import EmailMessage
import os
import logging
import threading

logger = logging.getLogger(__name__)

SMTP_SERVER = os.environ.get("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT = int(os.environ.get("SMTP_PORT", 587))
SMTP_USERNAME = os.environ.get("SMTP_USERNAME", "")
SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")

def _send_email_sync(to_email: str, subject: str, content: str):
    if not SMTP_USERNAME or not SMTP_PASSWORD:
        logger.warning(f"Email credentials not configured. Skipping email to {to_email} with subject: {subject}")
        return

    msg = EmailMessage()
    msg.set_content(content)
    msg['Subject'] = subject
    msg['From'] = SMTP_USERNAME
    msg['To'] = to_email

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SMTP_USERNAME, SMTP_PASSWORD)
        server.send_message(msg)
        server.quit()
        logger.info(f"Email sent successfully to {to_email}")
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {str(e)}")

def send_email_async(to_email: str, subject: str, content: str):
    # Run email sending in a separate thread so it doesn't block the API
    thread = threading.Thread(target=_send_email_sync, args=(to_email, subject, content))
    thread.start()

def send_staff_invitation_email(email: str, full_name: str, temp_password: str):
    subject = "Welcome to TailorSync - Staff Account Created"
    content = f"""Hello {full_name},

An account has been created for you on TailorSync! 
You can now log in and start managing your assigned tasks.

Your login credentials are:
Email: {email}
Password: {temp_password}

Please log in and change your password as soon as possible.

Best regards,
TailorSync Team
"""
    send_email_async(email, subject, content)

def send_task_assignment_email(email: str, full_name: str, order_number: str, garment_type: str):
    subject = f"New Task Assigned: Order {order_number}"
    content = f"""Hello {full_name},

You have been assigned a new task on TailorSync!

Order Details:
Order Number: {order_number}
Garment Type: {garment_type}

Please log in to your account to view the full details and manage this order.

Best regards,
TailorSync Team
"""
    send_email_async(email, subject, content)

def send_staff_removal_email(email: str, full_name: str):
    subject = "TailorSync - Access Revoked"
    content = f"""Hello {full_name},

Your access to the TailorSync business account has been removed by the administrator. 

You will no longer be able to log in or view tasks. If you believe this is a mistake, please contact your manager.

Best regards,
TailorSync Team
"""
    send_email_async(email, subject, content)

def send_staff_deactivated_email(email: str, full_name: str):
    subject = "TailorSync - Account Suspended"
    content = f"""Hello {full_name},

Your TailorSync staff account has been temporarily deactivated by the administrator. 

You will not be able to log in during this period. Please contact your manager for more details.

Best regards,
TailorSync Team
"""
    send_email_async(email, subject, content)

def send_staff_reactivated_email(email: str, full_name: str):
    subject = "TailorSync - Account Reactivated"
    content = f"""Hello {full_name},

Good news! Your TailorSync staff account has been reactivated by the administrator. 

You can now log in and manage your assigned tasks again.

Best regards,
TailorSync Team
"""
    send_email_async(email, subject, content)
