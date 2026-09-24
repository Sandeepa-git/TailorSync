import json
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database.base import Base
from app.models.business import Business
from app.models.customer import Customer
from app.models.garment_type import GarmentType
from app.models.measurement_template import MeasurementTemplate
from app.models.measurement_field import MeasurementField
from app.models.order import Order
from app.models.measurement import Measurement
from app.schemas.order import OrderCreate
from app.services.order_service import create_order

engine = create_engine("postgresql://localhost/dev_db")
Base.metadata.create_all(engine)
db = sessionmaker(bind=engine)()

try:
    # Setup mock data
    b = db.query(Business).first()
    if not b:
        b = Business(name="Mock Business")
        db.add(b)
        db.commit()
        
    c = db.query(Customer).first()
    if not c:
        c = Customer(first_name="Dineth", business_id=b.business_id)
        db.add(c)
        db.commit()

    order = OrderCreate.parse_raw(f"""{{
      "customer_id": {c.customer_id},
      "garment_type": "Short Sleeve Shirt",
      "priority": "Medium",
      "measurements": [
        {{"field_name": "Chest", "value": 40.0, "is_ai_generated": true}}
      ],
      "selected_fabric": "Cotton-Linen Blend",
      "fabric_estimation": {{"recommended_quantity_meters": 2.0}}
    }}""")
    print("Calling create_order...")
    res = create_order(db, order, business_id=b.business_id)
    print("SUCCESS, order ID:", res.order_id)
except Exception as e:
    import traceback
    traceback.print_exc()
