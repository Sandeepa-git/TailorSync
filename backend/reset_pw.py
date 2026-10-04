from app.database.session import SessionLocal
from app.models.user import User
from app.core.security import get_password_hash

db = SessionLocal()
user = db.query(User).filter(User.email == 'agsvwimalasiri@gmail.com').first()
if user:
    print('Resetting password for testing...')
    user.hashed_password = get_password_hash('Password123!')
    db.commit()
    print('Password reset successfully.')
else:
    print('User not found.')
db.close()
