from sqlalchemy import Column, Integer, String, JSON
from app.database.base import Base

class FabricCatalog(Base):
    __tablename__ = "fabric_catalog"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    fabric_type = Column(String, nullable=False) # e.g., Cotton, Silk, Linen
    characteristics = Column(JSON, default=list) # e.g., ["Breathable", "Lightweight"]
    suitability = Column(JSON, default=list) # e.g., ["Casual", "Summer", "Shirts"]
