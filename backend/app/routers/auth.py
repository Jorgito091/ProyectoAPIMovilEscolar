from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.user import UsuarioCreate, UsuarioOut, UsuarioLogin
from app.schemas.token import Token
from app.services.user_service import UserService
from app.dependencies import get_usuario_service
from app.utils.jwt import crear_access_token

router = APIRouter(prefix="/auth", tags=["Authentificación"])

@router.post("/register", response_model=UsuarioOut, status_code=status.HTTP_201_CREATED)
def register(
    user_data: UsuarioCreate,
    user_service: UserService = Depends(get_usuario_service)
):
    return user_service.crear_usuario(user_data)

@router.post("/login", response_model=Token)
def login(
    credentials: UsuarioLogin,
    user_service: UserService = Depends(get_usuario_service)
):
    user = user_service.autentificar_usuario(credentials.matricula, credentials.password)
    if not user:
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    token_data = {
        "sub": str(user.matricula),
        "id": user.id,
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