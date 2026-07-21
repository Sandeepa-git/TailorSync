from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, Numeric, String, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class FabricEstimation(Base):
    __tablename__ = "fabric_estimations"
    
    estimation_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    required_length = Column(Numeric(10, 2), nullable=False)
    unit = Column(String, default="meters", nullable=False)
    confidence_score = Column(Numeric(5, 2), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="fabric_estimations")

    @hybrid_property
    def id(self):
        return self.estimation_id

    @id.setter
    def id(self, value):
        self.estimation_id = value

    @hybrid_property
    def required_length_m(self):
        return self.required_length

    @required_length_m.setter
    def required_length_m(self, value):
        self.required_length = value
