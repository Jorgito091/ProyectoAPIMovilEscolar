from fastapi.security import OAuth2PasswordBearer
from fastapi import Request, HTTPException , status , Depends
from jose import JWTError, jwt
from app.utils.jwt import SECRET_KEY, ALGORITHM
from typing import Union, List

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def auth_middleware(request: Request, call_next):
    token = request.headers.get("Authorization")
    
    if not token or token != "Bearer secrettoken":
        raise HTTPException(status_code=401, detail="No autorizado")

    # Guardamos el "usuario" en el contexto
    request.state.user = {"id": 1, "role": "admin"}

    return await call_next(request)

def obtener_usuario(
    rol_requerido: Union[str, List[str]], 
    token: str = Depends(oauth2_scheme)
):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar la credencial",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        matricula: str = payload.get("sub")
        rol: str = payload.get("rol")
        id: int = payload.get("id")
        nombre: str = payload.get("nombre")
        if matricula is None or rol is None:
            raise credentials_exception
        usuario = {"matricula": matricula, "rol": rol, "id": id, "nombre": nombre}
    except JWTError:
        raise credentials_exception
    
    roles_permitidos = [rol_requerido] if isinstance(rol_requerido, str) else rol_requerido
    
    if rol not in roles_permitidos:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"No tienes permisos para acceder a este recurso. Roles permitidos: {', '.join(roles_permitidos)}",
        )
    return usuario

def crear_dependencia_auth(roles: Union[str, List[str]]):

    def dependency(token: str = Depends(oauth2_scheme)):
        return obtener_usuario(roles, token)
    return dependency

verificar_maestro = crear_dependencia_auth("maestro")
verificar_alumno = crear_dependencia_auth("alumno")
verificar_maestro_o_alumno = crear_dependencia_auth(["maestro", "alumno"])


def obtener_usuario_sin_rol(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudo validar la credencial",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        matricula: str = payload.get("sub")
        rol: str = payload.get("rol")
        id: int = payload.get("id")
        nombre: str = payload.get("nombre")
        if matricula is None:
            raise credentials_exception
        usuario = {"matricula": matricula, "rol": rol, "id": id, "nombre": nombre}
    except JWTError:
        raise credentials_exception
    return usuario

