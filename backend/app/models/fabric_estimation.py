from sqlalchemy import Column, Integer, ForeignKey, Float, String
from app.database.base import Base

class FabricEstimation(Base):
    __tablename__ = "fabric_estimations"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    garment_type = Column(String)
    required_length_m = Column(Float)
    details = Column(String)
