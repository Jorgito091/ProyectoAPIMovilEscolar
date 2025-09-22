from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Tarea(Base):
    __tablename__ = "tareas"
    id = Column(Integer, primary_key=True, index=True)
    alumno_id = Column(Integer, ForeignKey("users.id"))
    grupo_id = Column(Integer)
    titulo = Column(String)
    descripcion = Column(String, default="")
    completada = Column(Boolean, default=False)

    # Un alumno tiene muchas tareas
    alumno = relationship("User", back_populates="tareas")
