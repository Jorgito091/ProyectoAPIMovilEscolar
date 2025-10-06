from fastapi import HTTPException, status
from app.repositories.user_repo import UserRepository
from app.models.user import User
from typing import List
from passlib.context import CryptContext

# Instancia global de pwd_context para hashing y verificación de contraseñas
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    def crear_usuario(self, data) -> User:
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
        return self.repo.obtener_todos_por_rol(rol="alumno")

    def obtener_maestros(self) -> List[User]:
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

    def obtener_clases_por_alumno(self, alumno_id: int) -> list:
        """
        Devuelve las clases (grupos/materias) en las que está inscrito el alumno.
        """
        usuario = self.obtener_por_id(alumno_id)
        # usuario.inscripciones es una lista de Inscripcion, cada una tiene .clase
        if not hasattr(usuario, "inscripciones"):
            raise HTTPException(status_code=500, detail="El modelo User no tiene la relación 'inscripciones'")
        return [insc.clase for insc in usuario.inscripciones]