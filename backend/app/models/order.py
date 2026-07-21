from datetime import datetime
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Date, Numeric, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import object_session
from app.database.base import Base
from app.models.garment_type import GarmentType
import enum

class OrderStatus(enum.Enum):
    ORDER_RECEIVED = "Order Received"
    CUTTING = "Cutting"
    SEWING = "Sewing"
    FITTING = "Fitting"
    QUALITY_CHECK = "Quality Check"
    READY = "Ready"
    DELIVERED = "Delivered"

class OrderPriority(enum.Enum):
    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"

class Order(Base):
    __tablename__ = "orders"
    
    order_id = Column(Integer, primary_key=True, index=True)
    order_number = Column(String, unique=True, index=True, nullable=True)
    business_id = Column(Integer, ForeignKey("businesses.business_id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.customer_id"), nullable=False)
    garment_type_id = Column(Integer, ForeignKey("garment_types.garment_type_id"), nullable=True)
    occasion = Column(String, nullable=True)
    quantity = Column(Integer, default=1, nullable=True)
    expected_delivery_date = Column(Date, nullable=True)
    completed_date = Column(Date, nullable=True)
    status = Column(String, default="Order Received")
    priority = Column(String, default="Medium")
    total_price = Column(Numeric(10, 2), nullable=True)
    customer_instructions = Column(Text, nullable=True)
    tailor_remarks = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    customer = relationship("Customer", back_populates="orders")
    business = relationship("Business", back_populates="orders")
    staff_assignments = relationship("StaffAssignment", back_populates="order", cascade="all, delete-orphan")
    notes = relationship("Note", back_populates="order", cascade="all, delete-orphan")
    measurements = relationship("Measurement", back_populates="order", cascade="all, delete-orphan")
    ai_predictions = relationship("AIPrediction", back_populates="order", cascade="all, delete-orphan")
    fabric_estimations = relationship("FabricEstimation", back_populates="order", cascade="all, delete-orphan")
    fabric_recommendations = relationship("FabricRecommendation", back_populates="order", cascade="all, delete-orphan")
    garment_type_rel = relationship("GarmentType")

    @hybrid_property
    def id(self):
        return self.order_id

    @id.setter
    def id(self, value):
        self.order_id = value

    @hybrid_property
    def due_date(self):
        if self.expected_delivery_date is None:
            return None
        return datetime.combine(self.expected_delivery_date, datetime.min.time())

    @due_date.setter
    def due_date(self, value):
        if value is None:
            self.expected_delivery_date = None
        elif isinstance(value, datetime):
            self.expected_delivery_date = value.date()
        else:
            self.expected_delivery_date = value

    @hybrid_property
    def completed_at(self):
        if self.completed_date is None:
            return None
        return datetime.combine(self.completed_date, datetime.min.time())

    @completed_at.setter
    def completed_at(self, value):
        if value is None:
            self.completed_date = None
        elif isinstance(value, datetime):
            self.completed_date = value.date()
        else:
            self.completed_date = value

    @property
    def garment_type(self) -> str:
        if self.garment_type_rel:
            return self.garment_type_rel.name
        return ""

    @garment_type.setter
    def garment_type(self, value: str):
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
