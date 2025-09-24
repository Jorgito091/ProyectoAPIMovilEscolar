from pydantic import BaseModel
from datetime import datetime

class EntregaBase(BaseModel):
    tarea_id: int
    alumno_id: int
    url_archivo: str

class EntregaCreate(EntregaBase):
    pass

class EntregaOut(EntregaBase):
    id: int
    fecha_entrega: datetime

    class Config:
        orm_mode = True