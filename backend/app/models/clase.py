from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Clase(Base):
    __tablename__ = "clases"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, index=True, nullable=False)
    maestro_id = Column(Integer, ForeignKey("usuarios.id"))

    maestro = relationship("User", back_populates="clases_impartidas")
    
    inscripciones = relationship("Inscripcion", back_populates="clase")

    tareas = relationship("Tarea", back_populates="clase")
    asistencias = relationship("Asistencia", back_populates="clase")