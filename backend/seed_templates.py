import app.models
from app.database.session import SessionLocal
from app.models.measurement_template import MeasurementTemplate
from app.models.measurement_field import MeasurementField
from app.models.garment_type import GarmentType

def seed():
    db = SessionLocal()
    categories = {
        'Short Sleeve Shirt': [
            ("Shoulder Length", "cm", True),
            ("Height", "cm", True),
            ("Short Sleeve Length", "cm", False),
            ("Chest", "cm", False),
            ("Collar Size", "cm", False),
            ("Sleeve Opening", "cm", False)
        ],
        'Long Sleeve Shirt': [
            ("Shoulder Length", "cm", True),
            ("Height", "cm", True),
            ("Chest", "cm", False),
            ("Collar Size", "cm", False),
            ("Long Sleeve Length", "cm", False),
            ("Sleeve Opening", "cm", False)
        ],
        'Short Trouser': [
            ("Height Till Knee", "cm", True),
            ("Waist", "cm", True),
            ("Around Knee", "cm", False),
            ("Seat", "cm", False),
            ("Crotch", "cm", False),
            ("Short Trouser Leg Opening", "cm", False)
        ],
        'Long Trouser': [
            ("Height Till Knee", "cm", True),
            ("Waist", "cm", True),
            ("Around Knee", "cm", False),
            ("Seat", "cm", False),
            ("Crotch", "cm", False),
            ("Long Trouser Leg Opening", "cm", False)
        ],
        'Shirts': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Neck", "cm", False), ("Chest", "cm", False), ("Sleeve Length", "cm", False),
            ("Waist", "cm", False), ("Cuff", "cm", False)
        ],
        'Trousers': [
            ("Height Till Knee", "cm", True), ("Waist", "cm", True),
            ("Hip", "cm", False), ("Thigh", "cm", False), ("Inseam", "cm", False),
            ("Outseam", "cm", False), ("Bottom Width", "cm", False)
        ],
        'Jackets': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Sleeve Length", "cm", False),
            ("Jacket Length", "cm", False), ("Waist", "cm", False)
        ],
        'Dresses': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Bust", "cm", False), ("Waist", "cm", False), ("Hip", "cm", False),
            ("Dress Length", "cm", False)
        ],
        'Suits': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Waist", "cm", False), ("Hip", "cm", False),
            ("Sleeve Length", "cm", False), ("Inseam", "cm", False)
        ],
        'Coats': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Coat Length", "cm", False)
        ],
        'School Uniforms': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Waist", "cm", False), ("Length", "cm", False)
        ],
        'Office Uniforms': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Waist", "cm", False), ("Hip", "cm", False)
        ],
        'Waistcoats': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Waist", "cm", False)
        ],
        'Traditional': [
            ("Shoulder Length", "cm", True), ("Height", "cm", True),
            ("Chest", "cm", False), ("Waist", "cm", False), ("Hip", "cm", False)
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
