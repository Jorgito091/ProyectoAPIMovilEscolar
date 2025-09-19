from pydantic import BaseModel, Field
from typing import Optional, List, TYPE_CHECKING
from .tarea import TareaOut
from .base import UserBase

if TYPE_CHECKING:
    from .grupo import GrupoOut

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, example="MiPassword123")
    rol: Optional[str] = Field("alumno", example="alumno")
    grupo_id:int = None

class UserLogin(BaseModel):
    matricula: str = Field(..., example="A01234567")
    password: str = Field(..., min_length=6, example="MiPassword123")

class UserUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Juan Pérez")
    password: Optional[str] = Field(None, min_length=6, example="NuevoPassword456")
    activo: Optional[bool] = None
    rol: Optional[str] = Field(None, example="alumno")
    grupo_id: Optional[int] = None

class UserOut(UserBase):
    id: int
    rol: str
    grupo_id: Optional[int] = None
    tareas: List["TareaOut"] = []
    
    model_config = {
        "from_attributes": True
    }

# Modelo simple de grupo SOLO para usar dentro de UserWithGroup
class GrupoSimple(BaseModel):
    id: int
    nombre: str
    maestro_id: Optional[int] = None
    
    model_config = {
        "from_attributes": True
    }

# Modelo de usuario CON grupo (para casos específicos donde necesites la relación)
class UserWithGroup(UserBase):
    id: int
    rol: str
    grupo_id: Optional[int] = None
    grupo_asignado: Optional[GrupoSimple] = None
    tareas: List["TareaOut"] = []
    
    model_config = {
        "from_attributes": True
    }