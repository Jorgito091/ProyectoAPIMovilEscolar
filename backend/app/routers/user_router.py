from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.repositories.user_repo import UserRepository
from app.repositories.clase_repo import ClaseRepository
from app.models.user import User
from app.schemas.user import UsuarioCreate, UsuarioUpdate, UsuarioOut, UsuarioLogin, UsuarioOut
from app.schemas.token import Token
from app.database import get_db
from app.services.user_service import UserService
from passlib.context import CryptContext
from datetime import timedelta
from app.dependencies import get_usuario_service
from app.utils.jwt import crear_access_token
from app.middlewares.auth import obtener_usuario

router = APIRouter(prefix="/user", tags=["User"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.get("/me", response_model=UsuarioOut)
def read_users_me(current_user: dict = Depends(obtener_usuario), user_service: UserService = Depends(get_usuario_service)):
    # El ID del usuario viene del token decodificado por el middleware
    user_id = current_user.get("id")
    return user_service.obtener_por_id(user_id)

@router.get("/alumnos", response_model=List[UsuarioOut])
def listar_alumnos(
    user_service: UserService = Depends(get_usuario_service)
):
    return user_service.obtener_alumnos()

@router.get("/maestros", response_model=List[UsuarioOut])
def listar_maestros(
    user_service: UserService = Depends(get_usuario_service)
):
    return user_service.obtener_maestros()


@router.get("/{usuario_id}", response_model=UsuarioOut)
def read_user_by_id(usuario_id: int, user_service: UserService = Depends(get_usuario_service)):
    return user_service.obtener_por_id(usuario_id)


@router.put("/update/{user_id}", response_model=UsuarioOut)
def actualizar_usuario(
    user_id: int,
    update_data: UsuarioUpdate,
    user_service: UserService = Depends(get_usuario_service)
):
    data = update_data.dict(exclude_unset=True)
    if not data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar."
        )
    return user_service.actualizar_user(user_id, data)
