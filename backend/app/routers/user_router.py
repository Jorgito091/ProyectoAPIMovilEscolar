from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.repositories.user_repo import UserRepository
from app.repositories.grupo_repo import GrupoRepository
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserOut, UserWithGroup, UserLogin
from app.schemas.token import Token
from app.database import get_db
from app.services.user_service import UserService
from passlib.context import CryptContext
from datetime import timedelta
from app.utils.jwt import crear_access_token

router = APIRouter(prefix="/user", tags=["User"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_user_service(db: Session = Depends(get_db)):
    user_repo = UserRepository(db)
    grupo_repo = GrupoRepository(db)
    return UserService(user_repo, grupo_repo)

@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(
    user_data: UserCreate,
    user_service: UserService = Depends(get_user_service)
):
    return user_service.crear_usuario(user_data)

@router.post("/login", response_model=Token)
def login(
    credentials: UserLogin,
    user_service: UserService = Depends(get_user_service)
):
    user = user_service.autentificar_usuario(credentials.matricula, credentials.password)
    if not user:
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    token_data = {
        "sub": str(user.id),
        "rol": user.rol,
        "nombre": user.nombre
    }
    access_token = crear_access_token(token_data)
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "rol": user.rol,
        "alumno_id": user.id if user.rol == "alumno" else None
    }

@router.get("/alumnos", response_model=List[UserOut])
def listar_alumnos(
    user_service: UserService = Depends(get_user_service)
):
    return user_service.obtener_alumnos()

@router.get("/maestros", response_model=List[UserOut])
def listar_maestros(
    user_service: UserService = Depends(get_user_service)
):
    return user_service.obtener_maestros()

@router.put("/update/{user_id}", response_model=UserOut)
def actualizar_usuario(
    user_id: int,
    update_data: UserUpdate,
    user_service: UserService = Depends(get_user_service)
):
    data = update_data.dict(exclude_unset=True)
    if not data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar."
        )
    return user_service.actualizar_user(user_id, data)

@router.get("/user/{user_id}/with-group", response_model=UserWithGroup)
def obtener_usuario_con_grupo(
    user_id: int,
    user_service: UserService = Depends(get_user_service)
):
    user = user_service.obtener_por_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado"
        )
    return user