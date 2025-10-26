from pydantic import BaseModel, Field
from typing import Optional, List

class UsuarioBase(BaseModel):
    nombre: str = Field(..., example="Ana Soto")
    matricula: str = Field(..., example="A01700001")
    rol: str = Field(..., example="alumno")

class UsuarioCreate(UsuarioBase):
    password: str = Field(..., min_length=6, example="MiPasswordSeguro123")

class ClaseSimple(BaseModel):
    id: int
    nombre: str
    model_config = {"from_attributes": True}

class UsuarioLogin(BaseModel):
    matricula: str = Field(..., example="A01234567")
    password: str = Field(..., min_length=6, example="MiPassword123")

class UsuarioOut(UsuarioBase):
    id: int
    
    clases_inscritas: List[ClaseSimple] = []
    
    clases_impartidas: List[ClaseSimple] = []

    model_config = {"from_attributes": True}
    
    

class UsuarioUpdate(BaseModel):
    nombre: Optional[str] = Field(None, example="Ana Soto")
    matricula: Optional[str] = Field(None, example="A01700001")
    rol: Optional[str] = Field(None, example="alumno")
    password: Optional[str] = Field(None, min_length=6, example="MiPasswordSeguro123")