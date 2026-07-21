from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class MeasurementField(Base):
    __tablename__ = "measurement_fields"
    
    field_id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("measurement_templates.template_id"), nullable=False)
    field_name = Column(String, nullable=False)
    unit = Column(String, default="cm")
    required = Column(Boolean, default=True, nullable=False)
    display_order = Column(Integer, default=0)
    
    template = relationship("MeasurementTemplate", back_populates="fields")

    @hybrid_property
    def id(self):
        return self.field_id

    @id.setter
    def id(self, value):
        self.field_id = value

    @hybrid_property
    def is_required(self):
        return self.required

    @is_required.setter
    def is_required(self, value):
        self.required = value

    @property
    def placeholder(self):
        return None

    @placeholder.setter
    def placeholder(self, value):
        pass
