from sqlalchemy import Column, Integer, String, Text
from app.database.base import Base

class GarmentType(Base):
    __tablename__ = "garment_types"
    
    garment_type_id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    description = Column(Text, nullable=True)
