from pydantic import BaseModel, Field
from typing import Optional

class AlumnoBase(BaseModel):
    matricula: str = Field(..., example="A01234567")
    nombre: str = Field(..., example="Juan Pérez")
    activo: bool = True

class AlumnoCreate(AlumnoBase):
    password: str = Field(..., min_length=6, example="MiPassword123")

class AlumnoLogin(BaseModel):
    matricula: str = Field(..., example="A01234567")
    password: str = Field(..., min_length=6, example="MiPassword123")

class AlumnoOut(BaseModel):
    id: int
    matricula: str
    nombre: str
    activo: bool

    model_config = {
        "from_attributes": True
    }

class AlumnoUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Juan Pérez")
    password: Optional[str] = Field(None, min_length=6, example="NuevoPassword456")
    activo: Optional[bool] = None