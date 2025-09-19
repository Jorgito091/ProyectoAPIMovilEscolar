from fastapi import APIRouter, Depends,HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.user import UserCreate, UserLogin, UserOut
from app.repositories.user_repo import UserRepository
from app.services.user_service import UserService
from app.dependencies import get_user_service
from app.utils.jwt import crear_access_token

router = APIRouter(prefix="/user", tags=["User Auth"])

@router.post("/register", response_model=UserOut)
def register(
    user: UserCreate,
    user_service: UserService = Depends(get_user_service),
):
    user_creado = user_service.crear_usuario(user)
    return user_creado

@router.post("/login")
def login(
    data: UserLogin ,
    user_service: UserService = Depends(get_user_service)
):
    user = user_service.autentificar_usuario(data.matricula, data.password)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas"
        )
    token = crear_access_token({
        "sub": user.matricula,
        "id": user.id,
        "rol": user.rol
    })
    return {"access_token": token, "token_type": "bearer"} 

