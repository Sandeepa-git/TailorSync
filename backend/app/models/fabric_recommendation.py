from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, Numeric, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class FabricRecommendation(Base):
    __tablename__ = "fabric_recommendations"
    
    recommendation_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    fabric_id = Column(Integer, ForeignKey("fabric_catalog.fabric_id"), nullable=False)
    recommendation_score = Column(Numeric(5, 2), nullable=True)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="fabric_recommendations")
    fabric = relationship("FabricCatalog", back_populates="recommendations")

    @hybrid_property
    def id(self):
        return self.recommendation_id

    @id.setter
    def id(self, value):
        self.recommendation_id = value
