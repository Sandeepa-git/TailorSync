from datetime import datetime
from sqlalchemy import Column, Integer, ForeignKey, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base

class Note(Base):
    __tablename__ = "notes"
    
    note_id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    note = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    order = relationship("Order", back_populates="notes")
    author = relationship("User", back_populates="notes")

    @hybrid_property
    def id(self):
        return self.note_id

    @id.setter
    def id(self, value):
        self.note_id = value

    @hybrid_property
    def content(self):
        return self.note

    @content.setter
    def content(self, value):
        self.note = value
