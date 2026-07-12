from sqlalchemy import Column, Integer, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database.base import Base
from datetime import datetime

class CustomerMeasurement(Base):
    __tablename__ = "customer_measurements"
    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=False)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True) # Optional link to specific order
    field_id = Column(Integer, ForeignKey("measurement_fields.id"), nullable=False)
    value = Column(Float, nullable=True) # Float for the measurement value
    
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    customer = relationship("Customer")
    order = relationship("Order")
    field = relationship("MeasurementField")
