import app.models
from app.database.session import SessionLocal
from app.models.measurement_template import MeasurementTemplate
from app.models.measurement_field import MeasurementField
from app.models.garment_type import GarmentType

def seed():
    db = SessionLocal()
    categories = {
        'Short Sleeve Shirt': [
            ("Shoulder Length", "in", True),
            ("Height", "in", True),
            ("Short Sleeve Length", "in", False),
            ("Chest", "in", False),
            ("Collar Size", "in", False),
            ("Sleeve Opening", "in", False)
        ],
        'Long Sleeve Shirt': [
            ("Shoulder Length", "in", True),
            ("Height", "in", True),
            ("Chest", "in", False),
            ("Collar Size", "in", False),
            ("Long Sleeve Length", "in", False),
            ("Sleeve Opening", "in", False)
        ],
        'Short Trouser': [
            ("Height Till Knee", "in", True),
            ("Waist", "in", True),
            ("Around Knee", "in", False),
            ("Seat", "in", False),
            ("Crotch", "in", False),
            ("Short Trouser Leg Opening", "in", False)
        ],
        'Long Trouser': [
            ("Height Till Knee", "in", True),
            ("Waist", "in", True),
            ("Around Knee", "in", False),
            ("Seat", "in", False),
            ("Crotch", "in", False),
            ("Long Trouser Leg Opening", "in", False)
        ],
        'Shirts': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Neck", "in", False), ("Chest", "in", False), ("Sleeve Length", "in", False),
            ("Waist", "in", False), ("Cuff", "in", False)
        ],
        'Trousers': [
            ("Height Till Knee", "in", True), ("Waist", "in", True),
            ("Hip", "in", False), ("Thigh", "in", False), ("Inseam", "in", False),
            ("Outseam", "in", False), ("Bottom Width", "in", False)
        ],
        'Jackets': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Sleeve Length", "in", False),
            ("Jacket Length", "in", False), ("Waist", "in", False)
        ],
        'Dresses': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Bust", "in", False), ("Waist", "in", False), ("Hip", "in", False),
            ("Dress Length", "in", False)
        ],
        'Suits': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Waist", "in", False), ("Hip", "in", False),
            ("Sleeve Length", "in", False), ("Inseam", "in", False)
        ],
        'Coats': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Coat Length", "in", False)
        ],
        'School Uniforms': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Waist", "in", False), ("Length", "in", False)
        ],
        'Office Uniforms': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Waist", "in", False), ("Hip", "in", False)
        ],
        'Waistcoats': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Waist", "in", False)
        ],
        'Traditional': [
            ("Shoulder Length", "in", True), ("Height", "in", True),
            ("Chest", "in", False), ("Waist", "in", False), ("Hip", "in", False)
        ]
    }

    print("Seeding updated measurement templates...")
    for cat_name, fields in categories.items():
        g_type = db.query(GarmentType).filter(GarmentType.name == cat_name).first()
        if not g_type:
            g_type = GarmentType(name=cat_name)
            db.add(g_type)
            db.flush()

        template = db.query(MeasurementTemplate).filter(
            MeasurementTemplate.garment_type_id == g_type.garment_type_id,
            MeasurementTemplate.business_id == None
        ).first()

        if not template:
            template = MeasurementTemplate(garment_type_id=g_type.garment_type_id, business_id=None)
            db.add(template)
            db.flush()

        # Update fields cleanly
        existing_fields = {f.field_name.lower(): f for f in template.fields}
        for idx, (fname, unit, req) in enumerate(fields):
            if fname.lower() in existing_fields:
                existing_fields[fname.lower()].is_required = req
                existing_fields[fname.lower()].unit = unit
                existing_fields[fname.lower()].display_order = idx
            else:
                field = MeasurementField(
                    template_id=template.id,
                    field_name=fname,
                    unit=unit,
                    is_required=req,
                    display_order=idx
                )
                db.add(field)

    db.commit()
    db.close()
    print("Measurement templates seeded successfully!")

if __name__ == "__main__":
    seed()
