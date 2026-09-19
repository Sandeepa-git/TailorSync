import app.main  # to register all models
from app.database.session import SessionLocal
from app.services.order_service import create_order
from app.schemas.order import OrderCreate, DynamicMeasurementInput
from app.models.user import User

db = SessionLocal()
try:
    # get any user with a business
    user = db.query(User).filter(User.business_id.isnot(None)).first()
    if not user:
        print("No user with a business found")
        exit()
        
    print(f"Testing with business_id: {user.business_id}")
    
    # get a customer
    from app.models.customer import Customer
    customer = db.query(Customer).filter(Customer.business_id == user.business_id).first()
    if not customer:
        print("No customer found, creating one")
        customer = Customer(business_id=user.business_id, full_name="Test Customer", phone="123")
        db.add(customer)
        db.commit()
        db.refresh(customer)
        
    payload = OrderCreate(
        customer_id=customer.customer_id,
        garment_type="Shirt",
        priority="Medium",
        measurements=[DynamicMeasurementInput(field_id=1, value=10.5)]
    )
    
    order = create_order(db, payload, user.business_id)
    print("Order created successfully:", order.order_id)
except Exception as e:
    import traceback
    traceback.print_exc()
finally:
    db.rollback()
    db.close()
