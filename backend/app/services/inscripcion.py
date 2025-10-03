from fastapi import HTTPException, status
from app.repositories.inscripcion_repo import InscripcionRepository
from app.repositories.user_repo import UserRepository
from app.repositories.clase_repo import ClaseRepository
from app.models.inscripciones import Inscripcion
from app.schemas.inscripcion import InscripcionCreate

class InscripcionService:
    def __init__(self, inscripcion_repo: InscripcionRepository, usuario_repo: UserRepository, clase_repo: ClaseRepository):
        self.repo = inscripcion_repo
        self.usuario_repo = usuario_repo
        self.clase_repo = clase_repo

    def inscribir_alumno(self, data: InscripcionCreate) -> Inscripcion:
        alumno = self.usuario_repo.obtener_por_id(data.alumno_id)
        if not alumno or alumno.rol != 'alumno':
            raise HTTPException(status_code=404, detail="Alumno no encontrado.")

        clase = self.clase_repo.obtener_por_id(data.clase_id)
        if not clase:
            raise HTTPException(status_code=404, detail="Clase no encontrada.")

        existente = self.repo.buscar(alumno_id=data.alumno_id, clase_id=data.clase_id)
        if existente:
            raise HTTPException(status_code=400, detail="El alumno ya está inscrito en esta clase.")

        nueva_inscripcion = Inscripcion(**data.model_dump())
        return self.repo.crear(nueva_inscripcion)
    
