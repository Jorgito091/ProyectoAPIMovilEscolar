from fastapi import APIRouter, Depends, status
from app.schemas.inscripcion import InscripcionCreate, InscripcionOut
from app.services.inscripcion import InscripcionService
from app.dependencies import get_inscripcion_service
from app.middlewares.auth import verificar_maestro

router = APIRouter(prefix="/inscripciones", tags=["Inscripciones"])

@router.post("/", response_model=InscripcionOut, status_code=status.HTTP_201_CREATED, dependencies=[Depends(verificar_maestro)])
def inscribir_alumno_a_clase(
    inscripcion_data: InscripcionCreate,
    service: InscripcionService = Depends(get_inscripcion_service)
):
    return service.inscribir_alumno(inscripcion_data)