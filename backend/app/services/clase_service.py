from fastapi import HTTPException, status
from app.repositories.clase_repo import ClaseRepository
from app.repositories.user_repo import UserRepository
from app.models.clase import Clase
from app.schemas.clase import ClaseCreate, ClaseUpdate, ClaseOut, UsuarioSimple
from app.schemas.user import UsuarioOut

class ClaseService:
    """
    Servicio para la lógica de negocio relacionada con Clases.
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

    def obtener_por_id(self, clase_id: int) -> ClaseOut:
        """
        Devuelve la clase mapeada a ClaseOut, incluyendo alumnos_inscritos.
        (Mapeo explícito porque el nombre de la relación en el ORM es 'inscripciones'
        y el schema espera 'alumnos_inscritos'.)
        """
        clase = self.repo.obtener_por_id(clase_id)
        if not clase:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clase no encontrada")

        # mapear maestro
        maestro = UsuarioSimple.model_validate(clase.maestro) if getattr(clase, "maestro", None) else None

        # crear lista de alumnos a partir de la relación inscripciones -> insc.alumno
        alumnos = []
        for insc in getattr(clase, "inscripciones", []) or []:
            if getattr(insc, "alumno", None):
                alumnos.append(UsuarioSimple.model_validate(insc.alumno))

        clase_out = ClaseOut(
            id=clase.id,
            nombre=clase.nombre,
            maestro=maestro,
            alumnos_inscritos=alumnos
        )
        return clase_out

    def obtener_todas(self) -> list[Clase]:
        return self.repo.obtener_todas()

    def actualizar_clase(self, clase_id: int, data: ClaseUpdate):
        """
        Actualiza los datos de una clase.
        """
        clase = self.repo.obtener_por_id(clase_id)
        if not clase:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Clase no encontrada"
            )

        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(clase, key, value)

        
        return self.repo.actualizar(clase)

    def eliminar_clase(self, clase_id: int):
        """
        Elimina una clase por su ID.
        """
        clase = self.repo.obtener_por_id(clase_id)
        if not clase:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Clase no encontrada"
            )
        self.repo.eliminar(clase)
        return {"mensaje": f"Clase {clase_id} eliminado correctamente"}

    def obtener_alumno_por_clase(self, clase_id: int) -> list[UsuarioOut]:
        """
        Devuelve la lista de alumnos inscritos en la clase, mapeados al schema UsuarioOut.
        """
        # Verificar existencia de la clase
        clase = self.repo.obtener_por_id(clase_id)
        if not clase:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Clase no encontrada")

        alumnos = self.repo.obtener_alumnos_por_clase(clase_id)  # devuelve lista de modelos User

        # Mapear a UsuarioOut (Pydantic v2: model_validate)
        alumnos_out = [UsuarioOut.model_validate(u) for u in alumnos]
        return alumnos_out
