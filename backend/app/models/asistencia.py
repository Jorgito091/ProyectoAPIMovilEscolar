from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Asistencia(Base):
    __tablename__ = "asistencias"
    id = Column(Integer, primary_key=True, index=True)
    fecha_clase = Column(DateTime, default=datetime.utcnow)
    tema = Column(String, nullable=False)
    id_clase = Column(Integer, ForeignKey("clases.id"))
    id_alumno = Column(Integer, ForeignKey("usuarios.id"))

    clase = relationship("Clase", back_populates="asistencias")
    alumno = relationship("User", back_populates="asistencias")