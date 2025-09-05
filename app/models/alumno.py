from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from app.database import Base
from app.models.tarea import Tarea

class Alumno(Base):
    __tablename__ = "alumnos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String)
    matricula = Column(String, unique=True, index=True)
    activo = Column(Boolean, default=True)

    tareas = relationship("Tarea", back_populates="alumno")