from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Inscripcion(Base):
    __tablename__ = "inscripciones"
    alumno_id = Column(Integer, ForeignKey("usuarios.id"), primary_key=True)
    clase_id = Column(Integer, ForeignKey("clases.id"), primary_key=True)

    alumno = relationship("User", back_populates="inscripciones")
    clase = relationship("Clase", back_populates="inscripciones")