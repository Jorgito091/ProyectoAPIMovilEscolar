from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime

class Entrega(Base):
    __tablename__ = "entregas"
    id = Column(Integer, primary_key=True, index=True)
    tarea_id = Column(Integer, ForeignKey("tareas.id"), nullable=False)
    alumno_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    url_archivo = Column(String, nullable=False)
    fecha_entrega = Column(DateTime, default=datetime.utcnow)

    tarea = relationship("Tarea")
    alumno = relationship("User")