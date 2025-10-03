from sqlalchemy.orm import Session, selectinload
from app.models.user import User
from app.models.inscripciones import Inscripcion

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, usuario: User) -> User:
        self.db.add(usuario)
        self.db.commit()
        self.db.refresh(usuario)
        return usuario

    def obtener_por_matricula(self, matricula: str) -> User | None:
        return self.db.query(User).filter(User.matricula == matricula).first()

    def obtener_por_id(self, usuario_id: int) -> User | None:
        print(f"DEBUG REPO - Buscando usuario con ID: {usuario_id}, tipo: {type(usuario_id)}")
    
        usuario = self.db.query(User).options(
            selectinload(User.inscripciones).selectinload(Inscripcion.clase),
            selectinload(User.clases_impartidas)
        ).filter(User.id == usuario_id).first()
        
        print(f"DEBUG REPO - Usuario encontrado: {usuario}")
        if usuario:
            print(f"DEBUG REPO - Usuario ID: {usuario.id}, Matricula: {usuario.matricula}, Rol: {usuario.rol}")
        
        return usuario

    def obtener_todos_por_rol(self, rol: str) -> list[User]:
        return self.db.query(User).filter(User.rol == rol).all()
    
    def actualizar(self, usuario: User) -> User:
        self.db.commit()
        self.db.refresh(usuario)
        return usuario