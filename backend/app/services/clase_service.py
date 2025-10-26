from fastapi import HTTPException, status
from app.repositories.clase_repo import ClaseRepository
from app.repositories.user_repo import UserRepository
from app.models.clase import Clase
from app.schemas.clase import ClaseCreate,ClaseUpdate

class ClaseService:
    """
    Clase de servicio para manejar la lógica de negocio de los Clases.
    """
    def __init__(self, clase_repo: ClaseRepository, usuario_repo: UserRepository):
        self.repo = clase_repo
        self.usuario_repo = usuario_repo

    def crear_clase(self, data: ClaseCreate) -> Clase:
        maestro = self.usuario_repo.obtener_por_id(data.maestro_id)
        if not maestro or maestro.rol != "maestro":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El maestro especificado no existe o no tiene el rol correcto."
            )
        
        nueva_clase = Clase(**data.model_dump())
        return self.repo.crear(nueva_clase)

    def obtener_por_id(self, clase_id: int) -> Clase:
        clase = self.repo.obtener_por_id(clase_id)
        if not clase:
            raise HTTPException(status_code=404, detail="Clase no encontrada")
        return clase
    
    def obtener_todas(self) -> list[Clase]:
        return self.repo.obtener_todas()

    def actualizar_clase(self, Clase_id: int, data: ClaseUpdate):
        """
        Actualiza los datos de un Clase.
        """
        Clase = self.repo.obtener_por_id(Clase_id)
        if not Clase:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Clase no encontrado"
            )

        for key, value in data.dict(exclude_unset=True).items():
            setattr(Clase, key, value)
        
        return self.repo.actualizar(Clase)
    
    def eliminar_Clase(self, Clase_id: int):
        """
        Elimina un Clase por su ID.
        """
        Clase = self.repo.obtener_por_id(Clase_id)
        if not Clase:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Clase no encontrado"
            )
        self.repo.eliminar(Clase)
        return {"mensaje": f"Clase {Clase_id} eliminado correctamente"}
    
    def obtener_alumno_por_clase(self,Clase_id:int):
        return self.repo.obtener_alumnos_por_clase(Clase_id)


