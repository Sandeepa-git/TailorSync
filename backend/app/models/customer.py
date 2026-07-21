from datetime import datetime
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text, Date, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class Customer(Base):
    __tablename__ = "customers"
    
    customer_id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.business_id"), nullable=False)
    full_name = Column(String, nullable=False)
    phone = Column(String, index=True, nullable=True)
    email = Column(String, index=True, nullable=True)
    gender = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    address = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    orders = relationship("Order", back_populates="customer")
    business = relationship("Business", back_populates="customers")
    measurements = relationship("Measurement", back_populates="customer")

    @hybrid_property
    def id(self):
        return self.customer_id

    @id.setter
    def id(self, value):
        self.customer_id = value

    @hybrid_property
    def name(self):
        return self.full_name

    @name.setter
    def name(self, value):
        self.full_name = value
