from pydantic import BaseModel
from typing import Optional
from datetime import date  # <-- Importa date para las fechas
from .base import TareaBase

class TareaBase(BaseModel):
    titulo: str
    descripcion: Optional[str] = ""
    fecha_inicio: Optional[date] = None
    fecha_entrega: Optional[date] = None

class TareaCreate(TareaBase):
    grupo_id: int

class TareaOut(TareaBase):
    id: int
    grupo_id: int
    completada: Optional[bool] = False

    class Config:
        from_attributes = True

class TareaUpdate(BaseModel):
    titulo: Optional[str] = None
    descripcion: Optional[str] = None
    completada: Optional[bool] = None
    fecha_inicio: Optional[date] = None
    fecha_entrega: Optional[date] = None