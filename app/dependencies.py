from fastapi import Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.repositories.user_repo import UserRepository
from app.repositories.grupo_repo import GrupoRepository
from app.repositories.tarea_repo import TareaRepository
from app.services.user_service import UserService
from app.services.grupo_service import GrupoService
from app.services.tarea_service import TareaService

def get_user_repo(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepository(db)

def get_grupo_repo(db: Session = Depends(get_db)) -> GrupoRepository:
    return GrupoRepository(db)

def get_tarea_repo(db: Session = Depends(get_db)) -> TareaRepository:
    return TareaRepository(db)

def get_user_service(
    repo: UserRepository = Depends(get_user_repo), 
    repo_grupo: GrupoRepository = Depends(get_grupo_repo)
) -> UserService:
    return UserService(repo, repo_grupo)

def get_grupo_service(
    repo: GrupoRepository = Depends(get_grupo_repo), 
    repo_user: UserRepository = Depends(get_user_repo)
) -> GrupoService:
    return GrupoService(repo, repo_user)

def get_tarea_service(
    repo: TareaRepository = Depends(get_tarea_repo), 
    repo_grupo: GrupoRepository = Depends(get_grupo_repo)
) -> TareaService:
    return TareaService(repo, repo_grupo)