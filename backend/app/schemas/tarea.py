from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class TareaBase(BaseModel):
    titulo: str = Field(..., example="Proyecto Final")
    descripcion: Optional[str] = Field(None, example="Descripción del proyecto...")
    fecha_limite: datetime

class TareaCreate(TareaBase):
    clase_id: int

class TareaUpdate(BaseModel):
    titulo: Optional[str] = None
    descripcion: Optional[str] = None
    fecha_limite: Optional[datetime] = None

class TareaOut(TareaBase):
    id: int
    clase_id: int
    fecha_creacion: datetime
    
    model_config = {"from_attributes": True}