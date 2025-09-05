# app/routers/alumno_router.py
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.alumno import AlumnoCreate, AlumnoOut
from app.repositories.alumno_repo import AlumnoRepository
from app.services.alumno_service import AlumnoService

router = APIRouter(prefix="/alumnos", tags=["Alumnos"])

@router.post("/", response_model=AlumnoOut)
def crear_alumno(
    alumno: AlumnoCreate, 
    db: Session = Depends(get_db),
    request: Request = None  
):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    try:
        alumno_creado = service.crear_alumno(alumno.dict())
        # Log del middleware
        print(f"[DEBUG] Request ID: {request.state.request_id} | Crear alumno")
        return AlumnoOut.model_validate(alumno_creado)  # Pydantic v2
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=list[AlumnoOut])
def listar_alumnos(
    db: Session = Depends(get_db),
    request: Request = None  
):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    alumnos = service.obtener_alumnos()
    print(f"[DEBUG] Request ID: {request.state.request_id} | Listar alumnos")
    return [AlumnoOut.model_validate(a) for a in alumnos]