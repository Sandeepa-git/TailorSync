from sqlalchemy import Column, Integer, ForeignKey, JSON
from app.database.base import Base

class FabricRecommendation(Base):
    __tablename__ = "fabric_recommendations"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    recommendations = Column(JSON)
