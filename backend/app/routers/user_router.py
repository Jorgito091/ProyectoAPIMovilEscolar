from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.schemas.user import UsuarioCreate, UsuarioUpdate, UsuarioOut
from app.schemas.clase import ClaseOut, UsuarioSimple
from app.services.user_service import UserService
from app.dependencies import get_usuario_service

router = APIRouter(prefix="/user", tags=["User"])

@router.get("/me", response_model=UsuarioOut)
def read_users_me(
    current_user: dict = Depends(get_usuario_service),
    user_service: UserService = Depends(get_usuario_service)
):
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
def read_user_by_id(
    usuario_id: int,
    user_service: UserService = Depends(get_usuario_service)
):
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

@router.get("/{alumno_id}/clases", response_model=List[ClaseOut])
def obtener_clases_alumno(
    alumno_id: int,
    user_service: UserService = Depends(get_usuario_service)
):
    clases = user_service.obtener_clases_por_alumno(alumno_id)
    clases_out = []
    for clase in clases:
        alumnos = [UsuarioSimple.model_validate(insc.alumno) for insc in clase.inscripciones]
        clase_out = ClaseOut(
            id=clase.id,
            nombre=clase.nombre,
            maestro=UsuarioSimple.model_validate(clase.maestro),
            alumnos_inscritos=alumnos
        )
        clases_out.append(clase_out)
    return clases_out