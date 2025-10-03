from fastapi import APIRouter, Depends, status, File, UploadFile
from typing import List
from app.schemas.entrega import EntregaCreate, EntregaOut
from app.services.entrega_service import EntregaService
from app.dependencies import get_entrega_service
from app.middlewares.auth import verificar_alumno
from app.services.storage_service import StorageService 

router = APIRouter(prefix="/entregas", tags=["Entregas"])
storage_service = StorageService() 

@router.post("/tarea/{tarea_id}", response_model=EntregaOut, status_code=status.HTTP_201_CREATED)
async def crear_entrega_para_tarea(
    tarea_id: int,
    file: UploadFile = File(...),
    current_user: dict = Depends(verificar_alumno),
    service: EntregaService = Depends(get_entrega_service)
):
    user_name = current_user.get("nombre")
    alumno_id = current_user.get("id")
    storage_path = await storage_service.upload_file(file=file, user_name=user_name)

    entrega_data = EntregaCreate(storage_path=storage_path)
    return service.crear_entrega(alumno_id=alumno_id, tarea_id=tarea_id, data=entrega_data)

@router.get("/tarea/{tarea_id}", response_model=List[EntregaOut])
def listar_entregas_por_tarea(tarea_id: int, service: EntregaService = Depends(get_entrega_service)):
    return service.obtener_entregas_por_tarea(tarea_id)