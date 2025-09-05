from app.repositories.alumno_repo import AlumnoRepository
from app.models.alumno import Alumno

class AlumnoService:
    def __init__(self, repo: AlumnoRepository):
        self.repo = repo

    def crear_alumno(self, data: dict):
        existente = self.repo.obtener_por_matricula(data["matricula"])
        if existente:
            raise ValueError("Matrícula ya existe")
        nuevo = Alumno(**data)
        return self.repo.crear(nuevo)

    def obtener_alumnos(self):
        return self.repo.obtener_todos()