from pydantic import BaseModel, Field
from typing import Optional, List

class UserBase(BaseModel):
    matricula: str = Field(..., example="A01234567")
    nombre: str = Field(..., example="Juan Pérez")
    activo: bool = True

class GrupoBase(BaseModel):
    id: int
    nombre: str = Field(..., example="Matemáticas Avanzadas")
    maestro_id: Optional[int] = Field(None, example=1)

class TareaBase(BaseModel):
    titulo: str
    descripcion: Optional[str] = ""
    completada: Optional[bool] = False