from fastapi import APIRouter, Depends
from typing import List
from app.schemas.clase import ClaseCreate, ClaseOut
from app.services.clase_service import ClaseService
from app.dependencies import get_clase_service
from app.middlewares.auth import verificar_maestro

router = APIRouter(prefix="/clases", tags=["Clases"])

@router.post("/", response_model=ClaseOut, status_code=201, dependencies=[Depends(verificar_maestro)])
def crear_clase(clase_data: ClaseCreate, service: ClaseService = Depends(get_clase_service)):
    return service.crear_clase(clase_data)

@router.get("/{clase_id}", response_model=ClaseOut)
def obtener_clase(clase_id: int, service: ClaseService = Depends(get_clase_service)):
    return service.obtener_por_id(clase_id)

@router.get("/", response_model=List[ClaseOut])
def listar_clases(service: ClaseService = Depends(get_clase_service)):
    return service.obtener_todas()