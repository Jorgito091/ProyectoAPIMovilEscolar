from fastapi import APIRouter, Depends, HTTPException, status
from app.middlewares.auth import obtener_usuario
from app.schemas.tarea import TareaCreate, TareaOut
from app.services.tarea_service import TareaService
from app.dependencies import get_tarea_service
from app.middlewares.auth import verificar_alumno,verificar_maestro,verificar_maestro_o_alumno

router = APIRouter(prefix="/tareas", tags=["Tareas"])

@router.post("/", response_model=TareaOut)
def crear_tarea(
    tarea: TareaCreate,
    service: TareaService = Depends(get_tarea_service),
    usuario_autenticado: dict = Depends(verificar_maestro),
):
    tarea_creada = service.crear_tarea(tarea)
    return TareaOut.model_validate(tarea_creada)

@router.get("/", response_model=list[TareaOut])
def listar_tareas(
    service: TareaService = Depends(get_tarea_service),
    usuario_autenticado: dict = Depends(verificar_maestro_o_alumno)
):
    tareas = service.obtener_todas()
    return [TareaOut.model_validate(t) for t in tareas]

@router.get("/completadas/{status}", response_model=list[TareaOut])
def tareas_por_estado(
    status: bool,
    service: TareaService = Depends(get_tarea_service),
    usuario_autenticado: dict = Depends(verificar_maestro_o_alumno)
):
    tareas = service.obtener_por_estado(status)
    return [TareaOut.model_validate(t) for t in tareas]

@router.get("/{id}", response_model=TareaOut)
def tarea_por_id(
    id: int,
    service: TareaService = Depends(get_tarea_service),
    usuario_autenticado: dict = Depends(verificar_maestro)
):
    tarea = service.obtener_por_id(id)
    return TareaOut.model_validate(tarea)

@router.delete("/{id}")
def eliminar_tarea(
    id: int,
    service: TareaService = Depends(get_tarea_service),
    usuario_autenticado: dict = Depends(verificar_maestro)
):
    service.eliminar_tarea(id)
    return {"mensaje": f"Tarea {id} eliminada correctamente"}