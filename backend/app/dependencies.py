from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db

from app.repositories import user_repo, clase_repo, tarea_repo, entrega_repo, inscripcion_repo
from app.services import user_service, clase_service, tarea_service, entrega_service, inscripcion

def get_usuario_repo(db: Session = Depends(get_db)) -> user_repo.UserRepository:
    return user_repo.UserRepository(db)

def get_clase_repo(db: Session = Depends(get_db)) -> clase_repo.ClaseRepository:
    return clase_repo.ClaseRepository(db)

def get_tarea_repo(db: Session = Depends(get_db)) -> tarea_repo.TareaRepository:
    return tarea_repo.TareaRepository(db)
    
def get_entrega_repo(db: Session = Depends(get_db)) -> entrega_repo.EntregaRepository:
    return entrega_repo.EntregaRepository(db)

def get_inscripcion_repo(db: Session = Depends(get_db)) -> inscripcion_repo.InscripcionRepository:
    return inscripcion_repo.InscripcionRepository(db)

def get_usuario_service(repo: user_repo.UserRepository = Depends(get_usuario_repo)) -> user_service.UserService:
    return user_service.UserService(repo)

def get_clase_service(
    clase_repo: clase_repo.ClaseRepository = Depends(get_clase_repo), 
    usuario_repo: user_repo.UserRepository = Depends(get_usuario_repo)
) -> clase_service.ClaseService:
    return clase_service.ClaseService(clase_repo, usuario_repo)

def get_inscripcion_service(
    inscripcion_repo: inscripcion_repo.InscripcionRepository = Depends(get_inscripcion_repo),
    usuario_repo: user_repo.UserRepository = Depends(get_usuario_repo),
    clase_repo: clase_repo.ClaseRepository = Depends(get_clase_repo)
) -> inscripcion.InscripcionService:
    return inscripcion.InscripcionService(inscripcion_repo, usuario_repo, clase_repo)

def get_tarea_service(
    tarea_repo: tarea_repo.TareaRepository = Depends(get_tarea_repo), 
    clase_repo: clase_repo.ClaseRepository = Depends(get_clase_repo)
) -> tarea_service.TareaService:
    return tarea_service.TareaService(tarea_repo, clase_repo)
    
def get_entrega_service(
    entrega_repo: entrega_repo.EntregaRepository = Depends(get_entrega_repo), 
    tarea_repo: tarea_repo.TareaRepository = Depends(get_tarea_repo),
    usuario_repo: user_repo.UserRepository = Depends(get_usuario_repo)
) -> entrega_service.EntregaService:
    return entrega_service.EntregaService(entrega_repo, tarea_repo, usuario_repo)