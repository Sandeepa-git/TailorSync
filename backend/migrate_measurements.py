from app.database.session import SessionLocal
from app.models.measurement import Measurement
from app.models.measurement_template import MeasurementTemplate
from app.models.measurement_field import MeasurementField
from app.models.customer_measurement import CustomerMeasurement
from app.database.base import Base
from app.database.session import engine

# Import all models to register them in Base.metadata
import app.models.user
import app.models.business
import app.models.customer
import app.models.order
import app.models.staff_assignment
import app.models.note
import app.models.fabric_catalog
import app.models.fabric_estimation
import app.models.fabric_recommendation
import app.models.ai_prediction

def migrate():
    print("Creating new tables...")
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # 1. Create Default Templates for the 10 categories
    categories = {
        'Shirts': [
            ("Neck", "cm", True), ("Chest", "cm", True), ("Shoulder", "cm", True),
            ("Sleeve Length", "cm", True), ("Shirt Length", "cm", True),
            ("Waist", "cm", False), ("Cuff", "cm", False), ("Bicep", "cm", False)
        ],
        'Trousers': [
            ("Waist", "cm", True), ("Hip", "cm", True), ("Thigh", "cm", True),
            ("Knee", "cm", True), ("Inseam", "cm", True), ("Outseam", "cm", True),
            ("Bottom Width", "cm", True), ("Rise", "cm", True)
        ],
        'Jackets': [
            ("Chest", "cm", True), ("Shoulder", "cm", True), ("Sleeve Length", "cm", True),
            ("Jacket Length", "cm", True), ("Waist", "cm", True), ("Neck", "cm", True)
        ],
        'Dresses': [
            ("Bust", "cm", True), ("Waist", "cm", True), ("Hip", "cm", True),
            ("Shoulder", "cm", True), ("Dress Length", "cm", True), ("Sleeve Length", "cm", True)
        ],
        'Suits': [
            ("Chest", "cm", True), ("Waist", "cm", True), ("Hip", "cm", True),
            ("Shoulder", "cm", True), ("Sleeve Length", "cm", True), ("Inseam", "cm", True),
            ("Outseam", "cm", True)
        ],
        'Coats': [
            ("Chest", "cm", True), ("Shoulder", "cm", True), ("Sleeve Length", "cm", True),
            ("Coat Length", "cm", True)
        ],
        'School Uniforms': [
            ("Chest", "cm", True), ("Waist", "cm", True), ("Shoulder", "cm", True),
            ("Length", "cm", True)
        ],
        'Office Uniforms': [
            ("Chest", "cm", True), ("Waist", "cm", True), ("Hip", "cm", True),
            ("Shoulder", "cm", True), ("Sleeve Length", "cm", True), ("Inseam", "cm", True)
        ],
        'Waistcoats': [
            ("Chest", "cm", True), ("Waist", "cm", True), ("Length", "cm", True)
        ],
        'Traditional': [
            ("Chest", "cm", True), ("Waist", "cm", True), ("Hip", "cm", True),
            ("Shoulder", "cm", True), ("Length", "cm", True)
        ],
        # Examples from user request
        'Crocs / Sandals': [
            ("Foot Length", "cm", True), ("Foot Width", "cm", True), ("Shoe Size", "numeric", True)
        ],
        'Shoes': [
            ("Shoe Size", "numeric", True), ("Foot Length", "cm", True), ("Foot Width", "cm", True)
        ],
        'Caps': [
            ("Head Circumference", "cm", True)
        ],
        'Belts': [
            ("Waist Size", "cm", True), ("Belt Length", "cm", True)
        ]
    }
    
    print("Seeding templates...")
    template_map = {} # category -> template
    for cat, fields in categories.items():
        template = db.query(MeasurementTemplate).filter(MeasurementTemplate.category_name == cat, MeasurementTemplate.business_id == None).first()
        if not template:
            template = MeasurementTemplate(category_name=cat, business_id=None)
            db.add(template)
            db.commit()
            db.refresh(template)
            
            # Add fields
            for idx, (name, unit, req) in enumerate(fields):
                field = MeasurementField(
                    template_id=template.id,
                    field_name=name,
                    unit=unit,
                    is_required=req,
                    display_order=idx
                )
                db.add(field)
            db.commit()
        template_map[cat] = template

    # We need a fallback "Legacy" template for old measurements if order garment_type doesn't match
    legacy_template = db.query(MeasurementTemplate).filter(MeasurementTemplate.category_name == "Legacy").first()
    if not legacy_template:
        legacy_template = MeasurementTemplate(category_name="Legacy", business_id=None)
        db.add(legacy_template)
        db.commit()
        db.refresh(legacy_template)
        
        legacy_fields = ["height", "weight", "chest", "waist", "hip", "shoulder", "sleeve_length", "inseam"]
        for idx, f in enumerate(legacy_fields):
            field = MeasurementField(
                template_id=legacy_template.id,
                field_name=f.capitalize(),
                unit="cm",
                is_required=False,
                display_order=idx
            )
            db.add(field)
        db.commit()

    legacy_field_objs = db.query(MeasurementField).filter(MeasurementField.template_id == legacy_template.id).all()
    legacy_field_map = {f.field_name.lower(): f for f in legacy_field_objs}

    print("Migrating old measurements...")
    old_measurements = db.query(Measurement).all()
    migrated_count = 0
    for m in old_measurements:
        # Avoid duplicating migration
        existing = db.query(CustomerMeasurement).filter(CustomerMeasurement.customer_id == m.customer_id, CustomerMeasurement.order_id == m.order_id).first()
        if existing:
            continue
            
        # Migrate fields
        for field_str in ["height", "weight", "chest", "waist", "hip", "shoulder", "sleeve_length", "inseam"]:
            val = getattr(m, field_str, None)
            if val is not None:
                field_obj = legacy_field_map.get(field_str)
                if field_obj:
                    cm = CustomerMeasurement(
                        customer_id=m.customer_id,
                        order_id=m.order_id,
                        field_id=field_obj.id,
                        value=val,
                        recorded_at=m.recorded_at
                    )
                    db.add(cm)
        migrated_count += 1
        
    db.commit()
    print(f"Migrated {migrated_count} old measurements.")
    
    db.close()
    print("Migration complete!")

if __name__ == "__main__":
    migrate()
