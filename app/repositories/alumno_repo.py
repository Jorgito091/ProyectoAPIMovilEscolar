from sqlalchemy.orm import Session
from app.models.alumno import Alumno

class AlumnoRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, alumno: Alumno):
        self.db.add(alumno)
        self.db.commit()
        self.db.refresh(alumno)
        return alumno

    def obtener_por_matricula(self, matricula: str):
        return self.db.query(Alumno).filter(Alumno.matricula == matricula).first()

    def obtener_todos(self):
        return self.db.query(Alumno).filter(Alumno.activo == True).all()

    def obtener_por_id(self, id: int):
        return self.db.query(Alumno).get(id)