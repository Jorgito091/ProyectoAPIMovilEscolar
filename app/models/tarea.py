# app/models/tarea.py
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Tarea(Base):
    __tablename__ = "tareas"
    id = Column(Integer, primary_key=True, index=True)
    alumnoId = Column(Integer, ForeignKey("alumnos.id"))
    titulo = Column(String)
    descripcion = Column(String, default="")
    completada = Column(Boolean, default=False)

    alumno = relationship("Alumno", back_populates="tareas")