# app/schemas/tarea.py
from pydantic import BaseModel
from typing import Optional

class TareaBase(BaseModel):
    titulo: str
    descripcion: Optional[str] = ""
    completada: Optional[bool] = False

class TareaCreate(TareaBase):
    alumnoId: int

class TareaOut(TareaBase):
    id: int
    alumnoId: int
    class Config:
        from_attributes = True