from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, DateTime, Numeric, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class Measurement(Base):
    __tablename__ = "measurements"
    
    measurement_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=True)
    customer_id = Column(Integer, ForeignKey("customers.customer_id"), nullable=False)
    field_id = Column(Integer, ForeignKey("measurement_fields.field_id"), nullable=False)
    value = Column(Numeric(10, 2), nullable=True)
    entered_by = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    is_ai_generated = Column(Boolean, default=False, nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="measurements")
    customer = relationship("Customer", back_populates="measurements")
    field = relationship("MeasurementField")
    entered_by_rel = relationship("User")

    @hybrid_property
    def id(self):
        return self.measurement_id

    @id.setter
    def id(self, value):
        self.measurement_id = value
