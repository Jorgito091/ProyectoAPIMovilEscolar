# app/schemas/alumno.py
from pydantic import BaseModel
from typing import Optional

class AlumnoBase(BaseModel):
    nombre: str
    matricula: str
    activo: Optional[bool] = True

class AlumnoCreate(AlumnoBase):
    pass

class AlumnoOut(AlumnoBase):
    id: int
    class Config:
        from_attributes = True  