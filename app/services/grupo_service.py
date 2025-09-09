from fastapi import HTTPException, status
from app.repositories.grupo_repo import GrupoRepository
from app.repositories.user_repo import UserRepository
from app.models.grupo import Grupo
from app.schemas.grupo import GrupoCreate, GrupoUpdate

class GrupoService:
    """
    Clase de servicio para manejar la lógica de negocio de los grupos.
    """
    def __init__(self, repo: GrupoRepository, user_repo: UserRepository):
        self.repo = repo
        self.user_repo = user_repo

    def crear_grupo(self, data: GrupoCreate):
        """
        Crea un nuevo grupo y lo asigna a un maestro.
        """
        # Verifica que el maestro exista y tenga el rol correcto
        maestro = self.user_repo.obtener_por_id(data.maestro_id)
        if not maestro or maestro.rol != "maestro":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El maestro especificado no existe o no tiene el rol correcto."
            )
        
        nuevo_grupo = Grupo(nombre=data.nombre, maestro_id=data.maestro_id)
        return self.repo.crear(nuevo_grupo)

    def obtener_todos(self):
        """
        Obtiene todos los grupos.
        """
        return self.repo.obtener_todos()

    def obtener_por_id(self, grupo_id: int):
        """
        Obtiene un grupo por su ID, cargando también sus alumnos y maestro.
        """
        grupo = self.repo.obtener_por_id_con_relaciones(grupo_id)
        if not grupo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grupo no encontrado"
            )
        return grupo

    def actualizar_grupo(self, grupo_id: int, data: GrupoUpdate):
        """
        Actualiza los datos de un grupo.
        """
        grupo = self.repo.obtener_por_id(grupo_id)
        if not grupo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grupo no encontrado"
            )

        for key, value in data.dict(exclude_unset=True).items():
            setattr(grupo, key, value)
        
        return self.repo.actualizar(grupo)
    
    def eliminar_grupo(self, grupo_id: int):
        """
        Elimina un grupo por su ID.
        """
        grupo = self.repo.obtener_por_id(grupo_id)
        if not grupo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grupo no encontrado"
            )
        self.repo.eliminar(grupo)
        return {"mensaje": f"Grupo {grupo_id} eliminado correctamente"}


