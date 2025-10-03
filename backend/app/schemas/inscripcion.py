from pydantic import BaseModel
from .clase import UsuarioSimple
from .user import ClaseSimple

class InscripcionCreate(BaseModel):
    alumno_id: int
    clase_id: int

class InscripcionOut(BaseModel):
    alumno: UsuarioSimple
    clase: ClaseSimple
    
    model_config = {"from_attributes": True}