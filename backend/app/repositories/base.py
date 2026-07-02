from typing import Generic, TypeVar
from sqlalchemy.orm import Session

ModelType = TypeVar("ModelType")

class BaseRepository(Generic[ModelType]):
    def __init__(self, db: Session, model: ModelType):
        self.db = db
        self.model = model

    def get(self, id: int):
        return self.db.query(self.model).get(id)

    def list(self, skip: int = 0, limit: int = 100):
        return self.db.query(self.model).offset(skip).limit(limit).all()

    def create(self, obj_in):
        obj = self.model(**obj_in)
        self.db.add(obj)
        self.db.commit()
        self.db.refresh(obj)
        return obj
