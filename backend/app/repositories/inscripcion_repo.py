from sqlalchemy.orm import Session
from app.models.inscripciones import Inscripcion

class InscripcionRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, inscripcion: Inscripcion) -> Inscripcion:
        self.db.add(inscripcion)
        self.db.commit()
        self.db.refresh(inscripcion)
        return inscripcion

    def buscar(self, alumno_id: int, clase_id: int) -> Inscripcion | None:
        return self.db.query(Inscripcion).filter_by(
            alumno_id=alumno_id, 
            clase_id=clase_id
        ).first()

    def eliminar(self, inscripcion: Inscripcion):
        self.db.delete(inscripcion)
        self.db.commit()