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
    # Le decimos a SQLAlchemy que use la columna `grupo_id` para esta relación
    grupo_asignado = relationship(
        "Grupo", 
        back_populates="alumnos", 
        foreign_keys=[grupo_id]
    )

    # Relación con las tareas (un usuario tiene muchas tareas)
    tareas = relationship("Tarea", back_populates="alumno", cascade="all, delete-orphan")

    # Relación con los grupos que este usuario es maestro (un maestro es responsable de muchos grupos)
    # Le decimos a SQLAlchemy que use la columna `maestro_id` de la tabla de Grupos para esta relación
    grupos_maestro = relationship(
        "Grupo", 
        back_populates="maestro", 
        foreign_keys="Grupo.maestro_id"
    )
