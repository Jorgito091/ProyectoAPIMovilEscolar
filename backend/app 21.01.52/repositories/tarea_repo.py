from sqlalchemy.orm import Session
from app.models.tarea import Tarea

class TareaRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, tarea: Tarea):
        self.db.add(tarea)
        self.db.commit()
        self.db.refresh(tarea)
        return tarea

    def obtener_todas(self):
        return self.db.query(Tarea).all()

    def obtener_por_id(self, id: int):
        return self.db.query(Tarea).get(id)

    def obtener_por_alumno(self, alumno_id: int):
        return self.db.query(Tarea).filter(Tarea.alumno_id == alumno_id).all()

    def obtener_por_estado(self, status: bool):
        return self.db.query(Tarea).filter(Tarea.completada == status).all()

    def obtener_por_grupo(self, grupo_id: int):
        return self.db.query(Tarea).filter(Tarea.grupo_id == grupo_id).all()

    def eliminar(self, tarea):
        self.db.delete(tarea)
        self.db.commit()
        
    def actualizar(self, tarea: Tarea, data: dict):
        for key, value in data.items():
            setattr(tarea, key, value)
        self.db.commit()
        self.db.refresh(tarea)
        return tarea