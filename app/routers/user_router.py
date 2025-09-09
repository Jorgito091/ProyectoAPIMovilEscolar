from fastapi import APIRouter, Depends
from app.schemas.user import UserCreate, UserOut
from app.services.user_service import UserService
from app.middlewares.auth import verificar_alumno,verificar_maestro,verificar_maestro_o_alumno
from app.dependencies import get_user_service

router = APIRouter(prefix="/user", tags=["User"])


@router.get("/alumnos", response_model=list[UserOut])
def listar_usuarios(
    user_service: UserService = Depends(get_user_service),
    usuario_autenticado: dict = Depends(verificar_maestro)
):
    users = user_service.obtener_alumnos()
    return [UserOut.model_validate(user) for user in users]

@router.get("/maestros", response_model=list[UserOut])
def listar_maestros(
    user_service: UserService = Depends(get_user_service),
    usuario_autenticado: dict = Depends(verificar_maestro)
):
    users = user_service.obtener_maestros()
    return [UserOut.model_validate(user) for user in users]

