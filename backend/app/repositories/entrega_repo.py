from sqlalchemy.orm import Session
from app.models.entrega import Entrega
from app.schemas.entrega import EntregaCreate

def create_entrega(db: Session, entrega: EntregaCreate):
    db_entrega = Entrega(**entrega.dict())
    db.add(db_entrega)
    db.commit()
    db.refresh(db_entrega)
    return db_entrega

def get_entregas_by_tarea(db: Session, tarea_id: int):
    return db.query(Entrega).filter(Entrega.tarea_id == tarea_id).all()

def get_entregas_by_alumno(db: Session, alumno_id: int):
    return db.query(Entrega).filter(Entrega.alumno_id == alumno_id).all()

def get_entrega(db: Session, entrega_id: int):
    return db.query(Entrega).filter(Entrega.id == entrega_id).first()