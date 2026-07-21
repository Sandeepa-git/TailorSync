from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class Business(Base):
    __tablename__ = "businesses"
    
    business_id = Column(Integer, primary_key=True, index=True)
    business_name = Column(String(100), nullable=False)
    address = Column(Text, nullable=True)
    phone = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    users = relationship("User", back_populates="business")
    customers = relationship("Customer", back_populates="business")
    orders = relationship("Order", back_populates="business")
    templates = relationship("MeasurementTemplate", back_populates="business")

    @hybrid_property
    def id(self):
        return self.business_id

    @id.setter
    def id(self, value):
        self.business_id = value

    @hybrid_property
    def name(self):
        return self.business_name

    @name.setter
    def name(self, value):
        self.business_name = value
