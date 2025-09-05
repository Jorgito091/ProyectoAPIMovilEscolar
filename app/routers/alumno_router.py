from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.alumno import AlumnoCreate, AlumnoOut
from app.repositories.alumno_repo import AlumnoRepository
from app.services.alumno_service import AlumnoService

router = APIRouter(prefix="/alumnos", tags=["Alumnos"])

@router.post("/", response_model=AlumnoOut)
def crear_alumno(alumno: AlumnoCreate, db: Session = Depends(get_db)):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    try:
        return service.crear_alumno(alumno.dict())
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=list[AlumnoOut])
def listar_alumnos(db: Session = Depends(get_db)):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    return service.obtener_alumnos()