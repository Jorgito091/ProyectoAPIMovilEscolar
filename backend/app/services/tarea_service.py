from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.repositories.tarea_repo import TareaRepository
from app.repositories.grupo_repo import GrupoRepository
from app.repositories.user_repo import UserRepository
from app.models.tarea import Tarea
from app.schemas.tarea import TareaCreate

class TareaService:
    def __init__(self, repo: TareaRepository, user_repo: UserRepository, grupo_repo: GrupoRepository):
        self.repo = repo
        self.user_repo = user_repo
        self.grupo_repo = grupo_repo

    def crear_tarea(self, data: TareaCreate):
        grupo = self.grupo_repo.obtener_por_id(data.grupo_id)
        if not grupo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El grupo especificado no existe."
            )
        # SOLO UNA TAREA POR GRUPO:
        nueva_tarea_data = data.model_dump()
        # Si tu modelo requiere alumno_id obligatorio, asegúrate que sea nullable o no lo incluyas aquí
        nueva_tarea = Tarea(**nueva_tarea_data)
        self.repo.crear(nueva_tarea)
        return nueva_tarea

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