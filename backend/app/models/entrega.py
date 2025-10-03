from sqlalchemy import Column, Float, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class Entrega(Base):
    __tablename__ = "entregas"
    id = Column(Integer, primary_key=True, index=True)
    storage_path = Column(String, nullable=False)
    fecha_entrega = Column(DateTime, default=datetime.utcnow)
    calificacion = Column(Float, nullable=True)
    comentarios = Column(String, nullable=True)
    
    tarea_id = Column(Integer, ForeignKey("tareas.id"), nullable=False)
    alumno_id = Column(Integer, ForeignKey("usuarios.id"), nullable=False)

    tarea = relationship("Tarea", back_populates="entregas")
    alumno = relationship("User", back_populates="entregas")