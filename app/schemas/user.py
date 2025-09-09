from pydantic import BaseModel, Field
from typing import Optional, List, TYPE_CHECKING
from .tarea import TareaOut
from .base import UserBase

if TYPE_CHECKING:
    from .grupo import GrupoOut

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, example="MiPassword123")
    rol: Optional[str] = Field("alumno", example="alumno")

class UserLogin(BaseModel):
    matricula: str = Field(..., example="A01234567")
    password: str = Field(..., min_length=6, example="MiPassword123")

class UserOut(UserBase):
    id: int
    rol: str
    
    grupo_id: Optional[int] = None
    grupo_asignado: Optional["GrupoOut"] = None

    tareas: List["TareaOut"] = []

    model_config = {
        "from_attributes": True
    }

class UserUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Juan Pérez")
    password: Optional[str] = Field(None, min_length=6, example="NuevoPassword456")
    activo: Optional[bool] = None
    rol: Optional[str] = Field(None, example="alumno")