from pydantic import BaseModel

class AlumnoCreate(BaseModel):
    matricula: str
    nombre: str
    password: str

class AlumnoLogin(BaseModel):
    matricula: str
    password: str

class AlumnoOut(BaseModel):
    id: int
    matricula: str
    nombre: str
    activo: bool