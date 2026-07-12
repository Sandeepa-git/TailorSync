from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database.base import Base

class MeasurementField(Base):
    __tablename__ = "measurement_fields"
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("measurement_templates.id"), nullable=False)
    field_name = Column(String, nullable=False) # e.g., "Chest", "Sleeve Length"
    unit = Column(String, default="cm") # e.g., "cm", "inches"
    is_required = Column(Boolean, default=True)
    placeholder = Column(String, nullable=True) # e.g., "Enter value"
    display_order = Column(Integer, default=0)

    # Relationships
    template = relationship("MeasurementTemplate", back_populates="fields")
