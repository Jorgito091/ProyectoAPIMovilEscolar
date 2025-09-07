# app/routers/tarea_router.py
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.tarea import TareaCreate, TareaOut
from app.repositories.tarea_repo import TareaRepository
from app.services.tarea_service import TareaService

router = APIRouter(prefix="/tareas", tags=["Tareas"])

@router.post("/", response_model=TareaOut)
def crear_tarea(
    tarea: TareaCreate,
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tarea_creada = service.crear_tarea(tarea.dict())
    return TareaOut.model_validate(tarea_creada)

@router.get("/", response_model=list[TareaOut])
def listar_tareas(
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tareas = service.obtener_todas()
    return [TareaOut.model_validate(t) for t in tareas]

@router.get("/completadas/{status}", response_model=list[TareaOut])
def tareas_por_estado(
    status: bool,
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tareas = service.obtener_por_estado(status)
    return [TareaOut.model_validate(t) for t in tareas]

@router.get("/{id}", response_model=TareaOut)
def tarea_por_id(
    id: int,
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tarea = service.obtener_por_id(id)
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    return TareaOut.model_validate(tarea)

@router.get("/alumno/{alumno_id}", response_model=list[TareaOut])
def tareas_por_alumno(
    alumno_id: int,
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tareas = service.obtener_por_alumno(alumno_id)
    return [TareaOut.model_validate(t) for t in tareas]

@router.delete("/{id}")
def eliminar_tarea(
    id: int,
    db: Session = Depends(get_db),
    request: Request = None
):
    repo = TareaRepository(db)
    service = TareaService(repo)
    tarea = service.obtener_por_id(id)
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    service.eliminar_tarea(tarea)
    return {"mensaje": f"Tarea {id} eliminada correctamente"}