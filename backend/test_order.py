import json
from app.database.session import SessionLocal
from app.schemas.order import OrderCreate
from app.services.order_service import create_order

db = SessionLocal()
try:
    order = OrderCreate.parse_raw("""{
      "customer_id": 1,
      "garment_type": "Short Sleeve Shirt",
      "priority": "Medium",
      "staff_id": 1,
      "measurements": [
        {"field_id": 1, "value": 40.0, "is_ai_generated": true}
      ],
      "selected_fabric": "Cotton-Linen Blend",
      "fabric_estimation": {"recommended_quantity_meters": 2.0}
    }""")
    print("Calling create_order...")
    res = create_order(db, order, business_id=1)
    print("SUCCESS", res.order_id)
except Exception as e:
    import traceback
    traceback.print_exc()
