from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.alumno import AlumnoCreate, AlumnoLogin, AlumnoOut
from app.repositories.alumno_repo import AlumnoRepository
from app.services.alumno_service import AlumnoService
from app.utils.jwt import crear_access_token

router = APIRouter(prefix="/alumno", tags=["Alumno Auth"])

@router.post("/register", response_model=AlumnoOut)
def register(alumno: AlumnoCreate, db: Session = Depends(get_db)):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    alumno_creado = service.crear_alumno(alumno.dict())
    return AlumnoOut(
        id=alumno_creado.id,
        matricula=alumno_creado.matricula,
        nombre=alumno_creado.nombre,
        activo=alumno_creado.activo
    )

@router.post("/login")
def login(data: AlumnoLogin, db: Session = Depends(get_db)):
    repo = AlumnoRepository(db)
    service = AlumnoService(repo)
    alumno = service.autenticar_alumno(data.matricula, data.password)
    if not alumno:
        # Lanzamos excepción genérica, será gestionada en exceptions.py
        raise Exception("Credenciales inválidas")
    token = crear_access_token({
        "sub": alumno.matricula,
        "id": alumno.id,
        "rol": "alumno"
    })
    return {"access_token": token, "token_type": "bearer"}