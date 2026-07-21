from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, JSON, DateTime, String, Numeric
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class AIPrediction(Base):
    __tablename__ = "ai_predictions"
    
    prediction_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=True)
    model_name = Column(String, nullable=True)
    input_data = Column(JSON, nullable=True)
    predicted_values = Column(JSON, nullable=True)
    confidence_score = Column(Numeric(5, 2), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="ai_predictions")

    @hybrid_property
    def id(self):
        return self.prediction_id

    @id.setter
    def id(self, value):
        self.prediction_id = value

    @hybrid_property
    def input(self):
        return self.input_data

    @input.setter
    def input(self, value):
        self.input_data = value

    @hybrid_property
    def output(self):
        return self.predicted_values

    @output.setter
    def output(self, value):
        self.predicted_values = value
