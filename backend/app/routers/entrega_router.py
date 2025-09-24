from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.schemas.entrega import EntregaCreate, EntregaOut
from app.services import entrega_service
from app.database import get_db

router = APIRouter(
    prefix="/entregas",
    tags=["entregas"]
)

@router.post("/", response_model=EntregaOut, status_code=status.HTTP_201_CREATED)
def crear_entrega(entrega: EntregaCreate, db: Session = Depends(get_db)):
    # Puedes agregar aquí validaciones para asegurarte que la tarea y el alumno existen
    return entrega_service.crear_entrega(db, entrega)

@router.get("/tarea/{tarea_id}", response_model=List[EntregaOut])
def listar_entregas_de_tarea(tarea_id: int, db: Session = Depends(get_db)):
    return entrega_service.listar_entregas_de_tarea(db, tarea_id)

@router.get("/alumno/{alumno_id}", response_model=List[EntregaOut])
def listar_entregas_de_alumno(alumno_id: int, db: Session = Depends(get_db)):
    return entrega_service.listar_entregas_de_alumno(db, alumno_id)

@router.get("/{entrega_id}", response_model=EntregaOut)
def obtener_entrega(entrega_id: int, db: Session = Depends(get_db)):
    entrega = entrega_service.obtener_entrega(db, entrega_id)
    if not entrega:
        raise HTTPException(status_code=404, detail="Entrega no encontrada")
    return entrega

@router.delete("/{entrega_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_entrega(entrega_id: int, db: Session = Depends(get_db)):
    entrega = entrega_service.obtener_entrega(db, entrega_id)
    if not entrega:
        raise HTTPException(status_code=404, detail="Entrega no encontrada")
    db.delete(entrega)
    db.commit()
    return