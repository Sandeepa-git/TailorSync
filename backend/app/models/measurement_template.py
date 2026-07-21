from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship, object_session
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base
from app.models.garment_type import GarmentType

class MeasurementTemplate(Base):
    __tablename__ = "measurement_templates"
    
    template_id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.business_id"), nullable=True) # Null for global/default templates
    garment_type_id = Column(Integer, ForeignKey("garment_types.garment_type_id"), nullable=True)
    display_order = Column(Integer, default=0)
    
    business = relationship("Business")
    fields = relationship("MeasurementField", back_populates="template", cascade="all, delete-orphan")
    garment_type_rel = relationship("GarmentType")

    @hybrid_property
    def id(self):
        return self.template_id

    @id.setter
    def id(self, value):
        self.template_id = value

    @hybrid_property
    def category_name(self):
        if self.garment_type_rel:
            return self.garment_type_rel.name
        return ""

    @category_name.setter
    def category_name(self, value):
        session = object_session(self)
        if session is not None and value:
            name_clean = value.strip().capitalize()
            g_type = session.query(GarmentType).filter(GarmentType.name == name_clean).first()
            if not g_type:
                g_type = GarmentType(name=name_clean)
                session.add(g_type)
                session.flush()
            self.garment_type_id = g_type.garment_type_id
            self.garment_type_rel = g_type
        elif value:
            self.garment_type_rel = GarmentType(name=value.strip().capitalize())

    @hybrid_property
    def garment_type(self):
        return self.category_name

    @garment_type.setter
    def garment_type(self, value):
        self.category_name = value
