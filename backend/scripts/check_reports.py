"""Runs the Reports calculation against YOUR database and prints the exact error, if any.
    venv\\Scripts\\python scripts\\check_reports.py --email owner@yourmail.com
"""
import argparse, os, sys, traceback, json
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from dotenv import load_dotenv
load_dotenv()
import app.models  # noqa
from app.database.session import SessionLocal
from app.models.user import User
from app.api.v1.routers.reports import build_overview

ap = argparse.ArgumentParser(); ap.add_argument("--email", required=True); ap.add_argument("--days", type=int, default=90)
a = ap.parse_args()
db = SessionLocal()
u = db.query(User).filter(User.email == a.email.strip()).first()
if not u:
    sys.exit(f"No user {a.email}")
try:
    r = build_overview(a.days, u, db)
    print("OK - reports work. KPIs:", json.dumps(r["kpis"], default=str))
    print("Inventory:", "none (staff)" if r["inventory"] is None else {k: v for k, v in r["inventory"].items() if k != "items"})
except Exception:
    print("REPORTS FAILED - send this to Claude:\n")
    traceback.print_exc()
