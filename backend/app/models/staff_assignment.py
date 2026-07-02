from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.orm import relationship
from app.database.base import Base
from datetime import datetime

class StaffAssignment(Base):
    __tablename__ = "staff_assignments"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    staff_id = Column(Integer, ForeignKey("users.id"))
    role = Column(String)
    assigned_at = Column(DateTime, default=datetime.utcnow)

    order = relationship("Order", back_populates="staff_assignments")
    staff = relationship("User")
