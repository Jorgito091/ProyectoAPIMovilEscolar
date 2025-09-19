# app/schemas/tarea.py
from pydantic import BaseModel
from typing import Optional
from .base import TareaBase

class TareaCreate(TareaBase):
    grupo_id: int

class TareaOut(TareaBase):
    id: int
    grupo_id: int
    class Config:
        from_attributes = True

class TareaUpdate(BaseModel):
    titulo: Optional[str] = None
    descripcion: Optional[str] = None
    completada: Optional[bool] = None