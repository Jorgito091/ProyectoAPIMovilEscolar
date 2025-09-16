from sqlalchemy.orm import Session, joinedload
from app.models.user import User

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, user: User):
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def obtener_por_matricula(self, matricula: str):
        return self.db.query(User).options(
            joinedload(User.grupo_asignado)
        ).filter(User.matricula == matricula).first()

    def obtener_todos_por_rol(self, rol: str):
        return self.db.query(User).options(
            joinedload(User.grupo_asignado),
            joinedload(User.grupos_maestro)
        ).filter(User.activo == True, User.rol == rol).all()
    
    def obtener_alumnos_por_grupo(self, grupo_id: int):
        return self.db.query(User).options(
            joinedload(User.grupo_asignado)
        ).filter(User.activo == True, User.rol == "alumno", User.grupo_id == grupo_id).all()

    def obtener_por_id(self, id: int):
        return self.db.query(User).options(
            joinedload(User.grupo_asignado)
        ).get(id)
    
    def actualizar(self, user: User):
        self.db.commit()
        self.db.refresh(user)
        return user