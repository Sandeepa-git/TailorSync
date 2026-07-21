from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class StaffAssignment(Base):
    __tablename__ = "staff_assignments"
    
    assignment_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    staff_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    assigned_role = Column(String, nullable=True)
    assignment_status = Column(String, default="Assigned", nullable=True)
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="staff_assignments")
    staff = relationship("User", back_populates="assignments")

    @hybrid_property
    def id(self):
        return self.assignment_id

    @id.setter
    def id(self, value):
        self.assignment_id = value

    @hybrid_property
    def role(self):
        return self.assigned_role

    @role.setter
    def role(self, value):
        self.assigned_role = value
