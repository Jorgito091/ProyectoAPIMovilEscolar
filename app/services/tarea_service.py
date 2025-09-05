# app/services/tarea_service.py
from app.repositories.tarea_repo import TareaRepository
from app.models.tarea import Tarea

class TareaService:
    def __init__(self, repo: TareaRepository):
        self.repo = repo

    def crear_tarea(self, data: dict):
        nueva = Tarea(**data)
        return self.repo.crear(nueva)

    def obtener_todas(self):
        return self.repo.obtener_todas()

    def obtener_por_id(self, id: int):
        return self.repo.obtener_por_id(id)

    def obtener_por_alumno(self, alumno_id: int):
        return self.repo.obtener_por_alumno(alumno_id)

    def obtener_por_estado(self, status: bool):
        return self.repo.obtener_por_estado(status)

    def eliminar_tarea(self, tarea):
        self.repo.eliminar(tarea)