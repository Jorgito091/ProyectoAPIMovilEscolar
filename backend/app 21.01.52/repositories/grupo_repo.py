from sqlalchemy.orm import Session, joinedload
from app.models.grupo import Grupo
from app.models.user import User

class GrupoRepository:
    def __init__(self, db: Session):
        self.db = db

    def crear(self, grupo: Grupo):
        self.db.add(grupo)
        self.db.commit()
        self.db.refresh(grupo)
        return grupo

    def obtener_todos(self):
        return self.db.query(Grupo).all()

    def obtener_por_id(self, id: int):
        return self.db.query(Grupo).get(id)

    def obtener_por_id_con_relaciones(self, id: int):
        return self.db.query(Grupo).options(
            joinedload(Grupo.maestro),
            joinedload(Grupo.alumnos)
        ).get(id)

    def actualizar(self, grupo: Grupo):
        self.db.commit()
        self.db.refresh(grupo)
        return grupo

    def eliminar(self, grupo: Grupo):
        self.db.delete(grupo)
        self.db.commit()
