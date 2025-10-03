from pydantic import BaseModel, Field
from typing import Optional, List
from .user import UsuarioOut

class ClaseBase(BaseModel):
    nombre: str = Field(..., example="Programación Avanzada")

class ClaseCreate(ClaseBase):
    maestro_id: int

class UsuarioSimple(BaseModel): 
    id: int
    nombre: str
    matricula: str
    model_config = {"from_attributes": True}

class ClaseUpdate(ClaseBase):
    nombre: Optional[str]
    maestro: Optional[UsuarioSimple]
    alumnos_inscritos: Optional[List[UsuarioSimple]]

class ClaseOut(ClaseBase):
    id: int
    maestro: UsuarioSimple
    alumnos_inscritos: List[UsuarioSimple] = []

    model_config = {"from_attributes": True}