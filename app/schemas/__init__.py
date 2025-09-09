# app/schemas/__init__.py
from .user import UserOut, UserCreate, UserLogin, UserUpdate
from .grupo import GrupoOut, GrupoCreate, GrupoUpdate
from .tarea import TareaOut, TareaCreate, TareaUpdate

# Reconstruir los modelos después de importar todos
UserOut.model_rebuild()
GrupoOut.model_rebuild()
TareaOut.model_rebuild()