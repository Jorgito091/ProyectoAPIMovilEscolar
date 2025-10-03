from fastapi import Depends , HTTPException , status
from sqlalchemy.orm import Session
from app.repositories.user_repo import UserRepository
from app.models.user import User
from app.schemas.user import UsuarioCreate
from passlib.context import CryptContext
from typing import List, Optional
from app.database import get_db


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    
    def __init__(self, repo: UserRepository):
        self.repo = repo

    def crear_usuario(self, data: UsuarioCreate) -> User:
        existente = self.repo.obtener_por_matricula(data.matricula)
        if existente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La matrícula ya existe"
            )
        
        hashed_password = pwd_context.hash(data.password)
        
        nuevo_usuario = User(
            matricula=data.matricula,
            nombre=data.nombre,
            hashed_password=hashed_password,
            rol=data.rol
        )
        return self.repo.crear(nuevo_usuario)

    def obtener_por_id(self, usuario_id: int) -> User:
        usuario = self.repo.obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return usuario
    
    def autentificar_usuario(self, matricula: str, password: str) -> User | None:
        user = self.repo.obtener_por_matricula(matricula)
        if not user or not pwd_context.verify(password, user.hashed_password):
            return None
        return user

    def obtener_alumnos(self) -> List[User]:
        """
        Devuelve todos los alumnos registrados.
        """
        return self.repo.obtener_todos_por_rol(rol="alumno")
    
    def obtener_maestros(self) -> List[User]:
        """
        Devuelve todos los maestros registrados.
        """
        return self.repo.obtener_todos_por_rol(rol="maestro")



    def actualizar_user(self, user_id: int, data: dict) -> User:
        user = self.repo.obtener_por_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado."
            )
        
        for key, value in data.items():
            if key == "password":
                setattr(user, "hashed_password", pwd_context.hash(value))
            else:
                setattr(user, key, value)
        self.repo.actualizar(user)
        return user

