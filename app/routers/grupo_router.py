from fastapi import APIRouter, Depends, HTTPException
from app.middlewares.auth import obtener_usuario
from app.schemas.grupo import GrupoCreate, GrupoOut
from app.services.grupo_service import GrupoService
from app.dependencies import get_grupo_service

router = APIRouter(prefix="/grupos", tags=["Grupos"])

@router.post("/", response_model=GrupoOut)
def crear_grupo(
    grupo: GrupoCreate,
    service: GrupoService = Depends(get_grupo_service),
    usuario_autenticado: dict = Depends(lambda: obtener_usuario(rol_requerido="maestro"))
):
    nuevo_grupo = service.crear_grupo(grupo)
    return GrupoOut.model_validate(nuevo_grupo)

@router.get("/", response_model=list[GrupoOut])
def listar_grupos(
    service: GrupoService = Depends(get_grupo_service),
    usuario_autenticado: dict = Depends(lambda: obtener_usuario(rol_requerido="maestro"))
):
    grupos = service.obtener_todos()
    return [GrupoOut.model_validate(grupo) for grupo in grupos]

@router.get("/{id}", response_model=GrupoOut)
def obtener_grupo_por_id(
    id: int,
    service: GrupoService = Depends(get_grupo_service),
    usuario_autenticado: dict = Depends(lambda: obtener_usuario(rol_requerido=["maestro", "alumno"]))
):
    grupo = service.obtener_por_id(id)
    return GrupoOut.model_validate(grupo)

@router.delete("/{id}")
def eliminar_grupo(
    id: int,
    service: GrupoService = Depends(get_grupo_service),
    usuario_autenticado: dict = Depends(lambda: obtener_usuario(rol_requerido="maestro"))
):
    service.eliminar_grupo(id)
    return {"mensaje": f"Grupo {id} eliminado correctamente"}
