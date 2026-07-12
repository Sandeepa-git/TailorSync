from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database.base import Base

class MeasurementTemplate(Base):
    __tablename__ = "measurement_templates"
    id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.id"), nullable=True) # Null for global/default templates
    category_name = Column(String, nullable=False, index=True) # e.g., "Shirts", "Trousers"
    display_order = Column(Integer, default=0)

    # Relationships
    business = relationship("Business")
    fields = relationship("MeasurementField", back_populates="template", cascade="all, delete-orphan")
