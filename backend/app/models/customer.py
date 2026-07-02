from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from app.database.base import Base
from datetime import datetime

class Customer(Base):
    __tablename__ = "customers"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"))
    name = Column(String, nullable=False)
    email = Column(String, index=True)
    phone = Column(String, index=True)
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    orders = relationship("Order", back_populates="customer")
    business = relationship("Business", back_populates="customers")
    measurements = relationship("Measurement", back_populates="customer")
