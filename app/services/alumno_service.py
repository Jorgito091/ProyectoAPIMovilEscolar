from app.repositories.alumno_repo import AlumnoRepository
from app.models.alumno import Alumno
from passlib.context import CryptContext
from typing import List, Optional

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class AlumnoService:
    def __init__(self, repo: AlumnoRepository):
        self.repo = repo

    def crear_alumno(self, data: dict) -> Alumno:
        """
        Registra un nuevo alumno. Hashea la contraseña antes de guardar.
        Lanza ValueError si la matrícula ya existe.
        """
        existente = self.repo.obtener_por_matricula(data["matricula"])
        if existente:
            raise ValueError("Matrícula ya existe")
        # Hasheamos la contraseña antes de guardar
        hashed_password = pwd_context.hash(data["password"])
        nuevo = Alumno(
            matricula=data["matricula"],
            nombre=data["nombre"],
            hashed_password=hashed_password,
            activo=True
        )
        return self.repo.crear(nuevo)

    def obtener_alumnos(self) -> List[Alumno]:
        """
        Devuelve todos los alumnos registrados.
        """
        return self.repo.obtener_todos()

    def autenticar_alumno(self, matricula: str, password: str) -> Optional[Alumno]:
        """
        Verifica las credenciales de un alumno.
        Devuelve el alumno si las credenciales son correctas, None si no.
        """
        alumno = self.repo.obtener_por_matricula(matricula)
        if not alumno or not pwd_context.verify(password, alumno.hashed_password):
            return None
        return alumno