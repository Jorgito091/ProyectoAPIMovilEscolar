from fastapi import Depends, HTTPException, status
from app.repositories.tarea_repo import TareaRepository
from app.repositories.grupo_repo import GrupoRepository
from app.models.tarea import Tarea
from app.schemas.tarea import TareaCreate

class TareaService:
    def __init__(self, repo: TareaRepository, grupo_repo: GrupoRepository):
        self.repo = repo
        self.grupo_repo = grupo_repo

    def crear_tarea(self, data: TareaCreate):
        grupo = self.grupo_repo.obtener_por_id(data.grupo_id)
        if not grupo:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El grupo especificado no existe."
            )
        nueva_tarea = Tarea(**data.dict())
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

    def obtener_por_grupo(self, grupo_id: int):
        return self.repo.obtener_por_grupo(grupo_id)

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