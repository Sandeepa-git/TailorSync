from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from app.database.base import Base
import enum

class RoleEnum(str, enum.Enum):
    OWNER = "OWNER"
    STAFF = "STAFF"

class User(Base):
    __tablename__ = "users"
    
    user_id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.business_id"), nullable=True)
    full_name = Column(String, nullable=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(20), nullable=True)
    password_hash = Column(String, nullable=False)
    role = Column(Enum(RoleEnum), default=RoleEnum.STAFF)
    is_active = Column(Boolean, default=True, nullable=False)
    last_login = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    business = relationship("Business", back_populates="users")
    notes = relationship("Note", back_populates="author")
    assignments = relationship("StaffAssignment", back_populates="staff")

    @hybrid_property
    def id(self):
        return self.user_id

    @id.setter
    def id(self, value):
        self.user_id = value

    @hybrid_property
    def hashed_password(self):
        return self.password_hash

    @hashed_password.setter
    def hashed_password(self, value):
        self.password_hash = value
