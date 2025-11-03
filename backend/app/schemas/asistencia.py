from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AsistenciaBase(BaseModel):
    tema: str
    fecha_clase: datetime

class AsistenciaCreate(AsistenciaBase):
    id_clase: int
    id_alumno: int

class AsistenciaUpdate(AsistenciaBase):
    tema: Optional[str]
    fecha_clase: Optional[datetime]

class AsistenciaOut(AsistenciaBase):
    id_clase: int
    id_alumno: int

    model_config = {"from_attributes": True}

class AsistenciaOutWithUsers(AsistenciaBase):
    nombre: str
    clase: str
    
    model_config = {"from_attributes": True}
