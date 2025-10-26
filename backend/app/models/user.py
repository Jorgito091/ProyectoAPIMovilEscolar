from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, nullable=False)
    matricula = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    rol = Column(String, default="alumno", nullable=False)

    # Relaciones
    inscripciones = relationship("Inscripcion", back_populates="alumno")
    entregas = relationship("Entrega", back_populates="alumno")
    clases_impartidas = relationship("Clase", back_populates="maestro")
    
    @property
    def clases_inscritas(self):
        return [inscripcion.clase for inscripcion in self.inscripciones]