from sqlalchemy import Column, Integer, String
from app.database import Base

class Maestro(Base):
    __tablename__ = "maestros"
    id = Column(Integer, primary_key=True, index=True)
    matricula = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    nombre = Column(String)