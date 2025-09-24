from sqlalchemy.orm import Session
from app.schemas.entrega import EntregaCreate
from app.repositories import entrega_repo

def crear_entrega(db: Session, entrega_data: EntregaCreate):
    return entrega_repo.create_entrega(db, entrega_data)

def listar_entregas_de_tarea(db: Session, tarea_id: int):
    return entrega_repo.get_entregas_by_tarea(db, tarea_id)

def listar_entregas_de_alumno(db: Session, alumno_id: int):
    return entrega_repo.get_entregas_by_alumno(db, alumno_id)

def obtener_entrega(db: Session, entrega_id: int):
    return entrega_repo.get_entrega(db, entrega_id)