

from fastapi import Request, HTTPException

async def auth_middleware(request: Request, call_next):
    token = request.headers.get("Authorization")
    
    if not token or token != "Bearer secrettoken":
        raise HTTPException(status_code=401, detail="No autorizado")

    # Guardamos el "usuario" en el contexto
    request.state.user = {"id": 1, "role": "admin"}

    return await call_next(request)