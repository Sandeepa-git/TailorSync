from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
from app.database.base import Base
import enum
from datetime import datetime

class OrderStatus(enum.Enum):
    ORDER_RECEIVED = "Order Received"
    CUTTING = "Cutting"
    SEWING = "Sewing"
    FITTING = "Fitting"
    QUALITY_CHECK = "Quality Check"
    READY = "Ready"
    DELIVERED = "Delivered"

class OrderPriority(enum.Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    customer_id = Column(Integer, ForeignKey("customers.id"))
    garment_type = Column(String, nullable=False)
    occasion = Column(String)
    status = Column(Enum(OrderStatus), default=OrderStatus.ORDER_RECEIVED)
    priority = Column(Enum(OrderPriority), default=OrderPriority.MEDIUM)
    due_date = Column(DateTime)
    completed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    tailor_remarks = Column(String, nullable=True)
    customer_instructions = Column(String, nullable=True)
    
    measurements = relationship("CustomerMeasurement", back_populates="order")
    staff_assignments = relationship("StaffAssignment", back_populates="order")
    notes = relationship("Note", back_populates="order")
    customer = relationship("Customer", back_populates="orders")
