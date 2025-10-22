from fastapi import HTTPException, status
from app.repositories.asistencia_repo import AsistenciaRepository
from app.repositories.clase_repo import ClaseRepository
from app.repositories.user_repo import UserRepository
from app.models.asistencia import Asistencia
from app.schemas.asistencia import AsistenciaCreate, AsistenciaUpdate

class AsistenciaService:
    """
    Clase de servicio para manejar la lógica de negocio de las Asistencias.
    """
    def __init__(self, asistencia_repo: AsistenciaRepository, clase_repo: ClaseRepository, usuario_repo: UserRepository):
        self.repo = asistencia_repo
        self.clase_repo = clase_repo
        self.usuario_repo = usuario_repo

    def crear_asistencia(self, data: AsistenciaCreate) -> Asistencia:
        clase = self.clase_repo.obtener_por_id(data.id_clase)
        if not clase:
            raise HTTPException(status_code=404, detail="Clase no encontrada")
        
        alumno = self.usuario_repo.obtener_por_id(data.id_alumno)
        if not alumno or alumno.rol != "alumno":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El alumno especificado no existe o no tiene el rol correcto."
            )
        
        nueva_asistencia = Asistencia(**data.model_dump())
        return self.repo.crear(nueva_asistencia)

    def obtener_por_id(self, asistencia_id: int) -> Asistencia:
        asistencia = self.repo.obtener_por_id(asistencia_id)
        if not asistencia:
            raise HTTPException(status_code=404, detail="Asistencia no encontrada")
        return asistencia
    
    def obtener_todas(self) -> list[Asistencia]:
        return self.repo.obtener_todas()

    def obtener_por_clase(self, id_clase:int) -> list[Asistencia]:
        clase = self.clase_repo.obtener_por_id(id_clase)
        if not clase:
            raise HTTPException(status_code=404, detail="Clase no encontrada")
        return self.repo.obtener_por_clase(id_clase)

    def obtener_por_alumno(self, id_alumno:int) -> list[Asistencia]:
        alumno = self.usuario_repo.obtener_por_id(id_alumno)
        if not alumno or alumno.rol != "alumno":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El alumno especificado no existe o no tiene el rol correcto."
            )
        return self.repo.obtener_por_alumno(id_alumno)

    def obtener_por_alumno_y_clase(self, id_alumno: int, id_clase: int) -> list[Asistencia]:
        alumno = self.usuario_repo.obtener_por_id(id_alumno)
        if not alumno or alumno.rol != "alumno":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                detail="El alumno especificado no existe o no tiene el rol correcto."
            )
        return self.repo.obtener_por_alumno_y_clase(id_alumno, id_clase)