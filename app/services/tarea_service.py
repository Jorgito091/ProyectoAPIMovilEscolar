# app/services/tarea_service.py
from sqlalchemy.orm import Session
from fastapi import Depends , HTTPException, status
from app.models import grupo
from app.repositories.tarea_repo import TareaRepository
from app.repositories.grupo_repo import GrupoRepository
from app.repositories.user_repo import UserRepository
from app.models.tarea import Tarea
from app.database import get_db
from app.schemas.tarea import TareaCreate
class TareaService:
    def __init__(self, repo: TareaRepository , user_repo:UserRepository , grupo_repo:GrupoRepository):
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
        
        alumnos = self.user_repo.obtener_alumnos_por_grupo(data.grupo_id)
        
        if not alumnos:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No hay alumnos en el grupo especificado."
            )
        tareas_creadas = []
        for alumno in alumnos:
            nueva_tarea_data = data.model_dump()
            nueva_tarea_data["alumno_id"] = alumno.id
            nueva_tarea = Tarea(**nueva_tarea_data)
            self.repo.crear(nueva_tarea)
            tareas_creadas.append(nueva_tarea)
            
        return tareas_creadas

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


