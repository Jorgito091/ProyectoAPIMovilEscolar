# app/schemas/grupo.py
from pydantic import BaseModel, Field
from typing import Optional, List, TYPE_CHECKING
from .base import GrupoBase

# Importar solo para type checking, evita circular imports en runtime
if TYPE_CHECKING:
    from .user import UserOut

class GrupoCreate(BaseModel):
    nombre: str = Field(..., example="Matemáticas Avanzadas")
    maestro_id: Optional[int] = Field(None, example=1)

class GrupoOut(GrupoBase):
    id: int
    maestro_id: Optional[int]
    maestro: Optional["UserOut"] = None
    alumnos: List["UserOut"] = []

    model_config = {
        "from_attributes": True
    }

class GrupoUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Matemáticas Avanzadas")
    maestro_id: Optional[int] = Field(None, example=1)