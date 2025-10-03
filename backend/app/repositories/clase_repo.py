from sqlalchemy.orm import Session, selectinload
from app.models.clase import Clase
from app.models.user import User
from app.models.inscripciones import Inscripcion

class ClaseRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, clase: Clase) -> Clase:
        self.db.add(clase)
        self.db.commit()
        self.db.refresh(clase)
        return clase

    def obtener_por_id(self, clase_id: int) -> Clase | None:
        return self.db.query(Clase).options(
            selectinload(Clase.maestro),
            selectinload(Clase.inscripciones).selectinload(Inscripcion.alumno)
        ).filter(Clase.id == clase_id).first()

    def obtener_todas(self) -> list[Clase]:
        return self.db.query(Clase).options(selectinload(Clase.maestro)).all()

    def eliminar(self, clase: Clase):
        self.db.delete(clase)
        self.db.commit()

    def obtener_alumnos_por_clase(self, clase_id: int) -> list[User]:
        # Consulta para obtener solo la lista de alumnos de una clase específica
        return self.db.query(User).join(Inscripcion).filter(Inscripcion.clase_id == clase_id).all()