from fastapi import APIRouter, Depends,status,HTTPException
from app.models import user
from app.schemas.user import UserCreate, UserOut, UserWithGroup,UserUpdate
from app.services.user_service import UserService
from app.middlewares.auth import verificar_maestro
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

@router.put("/update/{user_id}",response_model=UserOut)
async def actualizar_user(
    user_id: int,
    update_data:UserUpdate,
    user_service: UserService = Depends(get_user_service),
):
    data = update_data.dict(exclude_unset=True)
    if not data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No se enviaron datos para actualizar."
        )    
    
    user_updated = user_service.actualizar_user(user_id,data)
    
    if user_updated is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado :C ")
    
    return user_updated

@router.get("/user/{user_id}/with-group",response_model=UserWithGroup)
async def obtener_usuario_por_id(
    user_id:int,
    user_service: UserService = Depends(get_user_service)
):
    return user_service.obtener_por_id(user_id)