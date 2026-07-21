from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class FabricCatalog(Base):
    __tablename__ = "fabric_catalog"
    
    fabric_id = Column(Integer, primary_key=True, index=True)
    fabric_name = Column(String, nullable=False)
    fabric_type = Column(String, nullable=False)
    characteristics = Column(Text, nullable=True)
    suitable_for = Column(Text, nullable=True)
    
    recommendations = relationship("FabricRecommendation", back_populates="fabric", cascade="all, delete-orphan")

    @hybrid_property
    def id(self):
        return self.fabric_id

    @id.setter
    def id(self, value):
        self.fabric_id = value

    @hybrid_property
    def name(self):
        return self.fabric_name

    @name.setter
    def name(self, value):
        self.fabric_name = value

    @hybrid_property
    def suitability(self):
        return self.suitable_for

    @suitability.setter
    def suitability(self, value):
        self.suitable_for = value
