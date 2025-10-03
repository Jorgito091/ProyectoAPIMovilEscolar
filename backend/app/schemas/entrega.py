from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from .clase import UsuarioSimple
from .tarea import TareaOut

class EntregaCreate(BaseModel):
    storage_path: str

class EntregaUpdate(BaseModel):
    calificacion: Optional[float] = None
    comentarios: Optional[str] = None

class EntregaOut(BaseModel):
    id: int
    storage_path: str
    fecha_entrega: datetime
    calificacion: Optional[float] = None
    comentarios: Optional[str] = None
    
    alumno: UsuarioSimple
    tarea: TareaOut
    
    model_config = {"from_attributes": True}