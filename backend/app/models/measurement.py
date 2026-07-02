from sqlalchemy import Column, Integer, Float, String, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from app.database.base import Base
from datetime import datetime

class Measurement(Base):
    __tablename__ = "measurements"
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True) # Optional link to specific order
    
    # Core dimensions (cm)
    height = Column(Float)
    weight = Column(Float)
    chest = Column(Float)
    waist = Column(Float)
    hip = Column(Float)
    shoulder = Column(Float)
    sleeve_length = Column(Float)
    inseam = Column(Float)
    
    # Store which fields were predicted by AI vs manual
    predicted_fields = Column(JSON, default=list)
    
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship("Customer", back_populates="measurements")
    order = relationship("Order", back_populates="measurements")
