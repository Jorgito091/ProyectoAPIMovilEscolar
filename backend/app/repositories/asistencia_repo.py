from sqlalchemy.orm import Session, selectinload
from app.models.asistencia import Asistencia
from app.models.clase import Clase
from app.models.user import User

class AsistenciaRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, asistencia: Asistencia) -> Asistencia:
        self.db.add(asistencia)
        self.db.commit()
        self.db.refresh(asistencia)
        return asistencia

    def obtener_por_id(self, asistencia_id: int) -> Asistencia | None:
        return self.db.query(Asistencia).options(
            selectinload(Asistencia.clase),
            selectinload(Asistencia.alumno)
        ).filter(Asistencia.id == asistencia_id).first()

    def obtener_todas(self) -> list[Asistencia]:
        return self.db.query(Asistencia).options(
            selectinload(Asistencia.clase),
            selectinload(Asistencia.alumno)
        ).all()

    def obtener_por_clase(self, clase_id:int) -> list[Asistencia]:
        return self.db.query(Asistencia).options(
            selectinload(Asistencia.clase),
            selectinload(Asistencia.alumno)
        ).filter(Asistencia.id_clase == clase_id).all()
    
    def obtener_por_alumno(self, alumno_id:int) -> list[Asistencia]:
        return self.db.query(Asistencia).options(
            selectinload(Asistencia.clase),
            selectinload(Asistencia.alumno)
        ).filter(Asistencia.id_alumno == alumno_id).all()

    def obtener_por_alumno_y_clase(self, alumno_id: int, clase_id: int) -> list[Asistencia]:
        return self.db.query(Asistencia).options(
            selectinload(Asistencia.clase),
            selectinload(Asistencia.alumno)
        ).filter(
            Asistencia.id_alumno == alumno_id,
            Asistencia.id_clase == clase_id
        ).all()

    def eliminar(self, asistencia: Asistencia):
        self.db.delete(asistencia)
        self.db.commit()
    
