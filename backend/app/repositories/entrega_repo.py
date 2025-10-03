from sqlalchemy.orm import Session, selectinload
from app.models.entrega import Entrega

class EntregaRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, entrega: Entrega) -> Entrega:
        self.db.add(entrega)
        self.db.commit()
        self.db.refresh(entrega)
        return entrega

    def obtener_por_id(self, entrega_id: int) -> Entrega | None:
        return self.db.query(Entrega).options(
            selectinload(Entrega.alumno),
            selectinload(Entrega.tarea)
        ).filter(Entrega.id == entrega_id).first()

    def obtener_por_tarea(self, tarea_id: int) -> list[Entrega]:
        return self.db.query(Entrega).filter(Entrega.tarea_id == tarea_id).all()

    def obtener_por_alumno(self, alumno_id: int) -> list[Entrega]:
        return self.db.query(Entrega).filter(Entrega.alumno_id == alumno_id).all()
    
    def actualizar(self, entrega: Entrega) -> Entrega:
        self.db.commit()
        self.db.refresh(entrega)
        return entrega