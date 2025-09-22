from pydantic import BaseModel, Field
from typing import Optional, List, TYPE_CHECKING
from .base import GrupoBase
class UserSimple(BaseModel):
    id: int
    nombre: str
    matricula: str
    email: str
    rol: str
    
    model_config = {
        "from_attributes": True
    }

class GrupoOut(GrupoBase):
    id: int
    maestro_id: Optional[int]
    
    model_config = {
        "from_attributes": True
    }

class GrupoCreate(BaseModel):
    nombre: str = Field(..., example="Matemáticas Avanzadas")
    maestro_id: Optional[int] = Field(None, example=1)

class GrupoUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Matemáticas Avanzadas")
    maestro_id: Optional[int] = Field(None, example=1)

# Modelo de grupo CON usuarios (para casos específicos donde necesites la relación)
class GrupoWithUsers(GrupoBase):
    id: int
    maestro_id: Optional[int]
    maestro: Optional[UserSimple] = None
    alumnos: List[UserSimple] = []
    
    model_config = {
        "from_attributes": True
    }