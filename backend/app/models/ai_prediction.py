from sqlalchemy import Column, Integer, ForeignKey, JSON, DateTime, String
from sqlalchemy.orm import relationship
from app.database.base import Base
from datetime import datetime

class AIPrediction(Base):
    __tablename__ = "ai_predictions"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    input = Column(JSON)
    output = Column(JSON)
    model_name = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
