from fastapi import HTTPException, status
from app.repositories.entrega_repo import EntregaRepository
from app.repositories.tarea_repo import TareaRepository
from app.repositories.user_repo import UserRepository
from app.models.entrega import Entrega
from app.schemas.entrega import EntregaCreate, EntregaUpdate  # <- Importa EntregaUpdate

class EntregaService:
    def __init__(self, entrega_repo: EntregaRepository, tarea_repo: TareaRepository, usuario_repo: UserRepository):
        self.repo = entrega_repo
        self.tarea_repo = tarea_repo
        self.usuario_repo = usuario_repo

    def crear_entrega(self, usuario_id: int, tarea_id: int, data: EntregaCreate) -> Entrega:
        tarea = self.tarea_repo.obtener_por_id(tarea_id)
        if not tarea:
            raise HTTPException(status_code=404, detail="La tarea no existe.")

        usuario = self.usuario_repo.obtener_por_id(usuario_id)
        if not usuario:
            raise HTTPException(status_code=404, detail="El usuario no existe.")
        
        nueva_entrega = Entrega(
            alumno_id=usuario.id,
            tarea_id=tarea_id,
            storage_path=data.storage_path
        )
        return self.repo.crear(nueva_entrega)

    def obtener_entregas_por_tarea(self, tarea_id: int) -> list[Entrega]:
        return self.repo.obtener_por_tarea(tarea_id)

    def actualizar_entrega(self, entrega_id: int, data: EntregaUpdate) -> Entrega | None:
        entrega = self.repo.obtener_por_id(entrega_id)
        if not entrega:
            return None
        if data.calificacion is not None:
            entrega.calificacion = data.calificacion
        if data.comentarios is not None:
            entrega.comentarios = data.comentarios
        return self.repo.actualizar(entrega)