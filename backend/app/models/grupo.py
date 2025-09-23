from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base

class Grupo(Base):
    __tablename__ = "grupos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String, unique=True, index=True)
    
    maestro_id = Column(Integer, ForeignKey("users.id"))
    maestro = relationship(
        "User", 
        back_populates="grupos_maestro",
        foreign_keys=[maestro_id] 
    )
    
    alumnos = relationship(
        "User", 
        back_populates="grupo_asignado", 
        foreign_keys="User.grupo_id", 
        cascade="all, delete-orphan"
    )