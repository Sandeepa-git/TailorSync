from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.orm import relationship
from app.database.base import Base

class Business(Base):
    __tablename__ = "businesses"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    address = Column(String)
    phone = Column(String)
    users = relationship("User", back_populates="business")
    customers = relationship("Customer", back_populates="business")
