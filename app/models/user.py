from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String)
    matricula = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    activo = Column(Boolean, default=True)
    rol = Column(String, default="alumno")
    grupo_id = Column(Integer, ForeignKey("grupos.id"), nullable=True)

    # Relación del usuario con su grupo (un alumno pertenece a un grupo)
    grupo_asignado = relationship(
        "Grupo", 
        back_populates="alumnos", 
        foreign_keys=[grupo_id]
    )

    # <<< Elimina esta línea: >>>
    # tareas = relationship("Tarea", back_populates="alumno", cascade="all, delete-orphan")

    grupos_maestro = relationship(
        "Grupo", 
        back_populates="maestro", 
        foreign_keys="Grupo.maestro_id"
    )