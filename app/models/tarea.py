from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Date
from sqlalchemy.orm import relationship
from app.database import Base

class Tarea(Base):
    __tablename__ = "tareas"
    id = Column(Integer, primary_key=True, index=True)
    grupo_id = Column(Integer, ForeignKey("grupos.id"))  # Relación grupo
    titulo = Column(String)
    descripcion = Column(String, default="")
    fecha_inicio = Column(Date)
    fecha_entrega = Column(Date)
    completada = Column(Boolean, default=False)

    grupo = relationship("Grupo", back_populates="tareas")