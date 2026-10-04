from datetime import datetime
from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from app.database.base import Base


class InventoryItem(Base):
    """One fabric in a business's stock (meters).

    Rows are auto-created (untracked, 0 m) the first time a fabric is recommended
    or used. Nothing is deducted until the owner sets a stock amount (is_tracked).
    """
    __tablename__ = "inventory_items"
    __table_args__ = (UniqueConstraint("business_id", "name_key", name="uq_inventory_business_fabric"),)

    item_id = Column(Integer, primary_key=True, index=True)
    business_id = Column(Integer, ForeignKey("businesses.business_id"), nullable=False, index=True)
    fabric_name = Column(String, nullable=False)
    name_key = Column(String, nullable=False)  # normalized name used for matching
    quantity_m = Column(Numeric(10, 2), nullable=False, default=0)
    is_tracked = Column(Boolean, nullable=False, default=False)
    low_stock_threshold_m = Column(Numeric(10, 2), nullable=False, default=5)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    transactions = relationship("InventoryTransaction", back_populates="item",
                                cascade="all, delete-orphan", order_by="InventoryTransaction.created_at.desc()")


class InventoryTransaction(Base):
    """Stock history: restocks, order usage, manual adjustments, reversals."""
    __tablename__ = "inventory_transactions"

    transaction_id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, ForeignKey("inventory_items.item_id"), nullable=False, index=True)
    change_m = Column(Numeric(10, 2), nullable=False)          # + added, - used
    balance_after_m = Column(Numeric(10, 2), nullable=False)
    kind = Column(String, nullable=False)                      # RESTOCK | ORDER | ADJUST | REVERSAL
    order_id = Column(Integer, nullable=True, index=True)      # no FK: history survives order deletion
    note = Column(Text, nullable=True)
    user_id = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    item = relationship("InventoryItem", back_populates="transactions")
