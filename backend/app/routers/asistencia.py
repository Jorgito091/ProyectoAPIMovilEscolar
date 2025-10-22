from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from app.schemas.asistencia import AsistenciaCreate, AsistenciaOut
from app.services.asistencia_service import AsistenciaService
from app.dependencies import get_asistencia_service
from app.middlewares.auth import verificar_maestro, verificar_alumno

router = APIRouter(prefix="/asistencias", tags=["Asistencias"])

@router.post("/",response_model=AsistenciaOut,status_code=201,dependencies=[Depends(verificar_maestro)])
async def crear_asistencia(asistencia_data: AsistenciaCreate, service: AsistenciaService = Depends(get_asistencia_service)):
    return service.crear_asistencia(asistencia_data)

@router.get("/{asistencia_id}", response_model=AsistenciaOut)
async def obtener_asistencia(asistencia_id: int, service: AsistenciaService = Depends(get_asistencia_service)):
    return service.obtener_por_id(asistencia_id)

@router.get("/", response_model=List[AsistenciaOut],)
async def listar_asistencias(service: AsistenciaService = Depends(get_asistencia_service)):
    return service.obtener_todas()

@router.get("/clase/{id_clase}", response_model=List[AsistenciaOut], dependencies=[Depends(verificar_maestro)])
async def listar_asistencias_por_clase(id_clase: int, service: AsistenciaService = Depends(get_asistencia_service)):
    return service.obtener_por_clase(id_clase)

@router.get("/alumno/{id_alumno}", response_model=List[AsistenciaOut], dependencies=[Depends(verificar_alumno)])
async def listar_asistencias_por_alumno(id_alumno: int, service: AsistenciaService = Depends(get_asistencia_service)):
    return service.obtener_por_alumno(id_alumno)

@router.get("/alumno/{id_alumno}/clase/{id_clase}", response_model=List[AsistenciaOut], dependencies=[Depends(verificar_alumno)])
async def listar_asistencias_por_alumno_y_clase(id_alumno: int, id_clase: int, service: AsistenciaService = Depends(get_asistencia_service)):
    return service.obtener_por_alumno_y_clase(id_alumno, id_clase)
