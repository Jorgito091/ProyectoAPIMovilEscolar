from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.repositories.tarea_repo import TareaRepository
from app.repositories.clase_repo import ClaseRepository
from app.repositories.user_repo import UserRepository
from app.models.tarea import Tarea
from app.schemas.tarea import TareaCreate

class TareaService:
    def __init__(self, tarea_repo: TareaRepository, clase_repo: ClaseRepository):
        self.repo = tarea_repo
        self.clase_repo = clase_repo

    def crear_tarea(self, data: TareaCreate) -> Tarea:
        clase = self.clase_repo.obtener_por_id(data.clase_id)
        if not clase:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La clase especificada no existe."
            )
        
        nueva_tarea = Tarea(**data.model_dump())
        return self.repo.crear(nueva_tarea)

    def obtener_por_clase(self, clase_id: int) -> list[Tarea]:
        return self.repo.obtener_por_clase(clase_id)

    def obtener_todas(self):
        return self.repo.obtener_todas()

    def obtener_por_id(self, id: int):
        tarea = self.repo.obtener_por_id(id)
        if not tarea:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tarea no encontrada."
            )
        return tarea

    def obtener_por_alumno(self, alumno_id: int):
        return self.repo.obtener_por_alumno(alumno_id)

    def obtener_por_estado(self, status: bool):
        return self.repo.obtener_por_estado(status)

    def eliminar_tarea(self, id: int):
        tarea = self.repo.obtener_por_id(id)
        if not tarea:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tarea no encontrada."
            )
        self.repo.eliminar(tarea)
        return {"mensaje": f"Tarea {tarea.id} eliminada correctamente."}

    def obtener_por_grupo(self, grupo_id: int):
        """
        Devuelve una lista de tareas asociadas a un grupo.
        """
        return self.repo.obtener_por_grupo(grupo_id)

    def actualizar_tarea(self, id: int, data: dict):
        tarea = self.repo.obtener_por_id(id)
        if not tarea:
            raise HTTPException(status_code=404, detail="Tarea no encontrada")
        tarea_actualizada = self.repo.actualizar(tarea, data)
        return tarea_actualizada