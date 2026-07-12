from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.measurement_template import MeasurementTemplate
from app.models.measurement_field import MeasurementField
from app.schemas.template import MeasurementTemplateRead, MeasurementTemplateCreate, MeasurementTemplateUpdate, MeasurementFieldCreate

router = APIRouter()

@router.get("/", response_model=List[MeasurementTemplateRead])
def get_templates(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Get all templates for the current business + global templates."""
    templates = db.query(MeasurementTemplate).filter(
        or_(
            MeasurementTemplate.business_id == None,
            MeasurementTemplate.business_id == current_user.business_id
        )
    ).order_by(MeasurementTemplate.display_order).all()
    return templates

@router.get("/{category_name}", response_model=MeasurementTemplateRead)
def get_template_by_category(category_name: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    template = db.query(MeasurementTemplate).filter(
        MeasurementTemplate.category_name == category_name,
        or_(
            MeasurementTemplate.business_id == None,
            MeasurementTemplate.business_id == current_user.business_id
        )
    ).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template

@router.post("/", response_model=MeasurementTemplateRead)
def create_template(payload: MeasurementTemplateCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Check if a template for this category already exists for the business
    existing = db.query(MeasurementTemplate).filter(
        MeasurementTemplate.category_name == payload.category_name,
        MeasurementTemplate.business_id == current_user.business_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Template for this category already exists")
    
    template = MeasurementTemplate(
        category_name=payload.category_name,
        display_order=payload.display_order,
        business_id=current_user.business_id
    )
    db.add(template)
    db.commit()
    db.refresh(template)
    
    for idx, field_payload in enumerate(payload.fields):
        field = MeasurementField(
            template_id=template.id,
            field_name=field_payload.field_name,
            unit=field_payload.unit,
            is_required=field_payload.is_required,
            placeholder=field_payload.placeholder,
            display_order=field_payload.display_order if field_payload.display_order else idx
        )
        db.add(field)
    
    db.commit()
    db.refresh(template)
    return template

@router.put("/{template_id}", response_model=MeasurementTemplateRead)
def update_template(template_id: int, payload: MeasurementTemplateUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    template = db.query(MeasurementTemplate).filter(
        MeasurementTemplate.id == template_id,
        MeasurementTemplate.business_id == current_user.business_id
    ).first()
    
    if not template:
        raise HTTPException(status_code=404, detail="Template not found or not editable (global templates cannot be edited directly)")
        
    if payload.category_name is not None:
        template.category_name = payload.category_name
    if payload.display_order is not None:
        template.display_order = payload.display_order
        
    db.commit()
    db.refresh(template)
    return template

@router.delete("/{template_id}")
def delete_template(template_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    template = db.query(MeasurementTemplate).filter(
        MeasurementTemplate.id == template_id,
        MeasurementTemplate.business_id == current_user.business_id
    ).first()
    
    if not template:
        raise HTTPException(status_code=404, detail="Template not found or not editable")
        
    db.delete(template)
    db.commit()
    return {"status": "success", "detail": "Template deleted"}
