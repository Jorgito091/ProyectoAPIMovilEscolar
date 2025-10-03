from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

import logging
logger = logging.getLogger(__name__)



async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    print(f"[HTTP ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "request_id": getattr(request.state, "request_id", None)}
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """
    Handler personalizado para errores de validación que evita serializar FormData
    """
    errors = []
    for error in exc.errors():
        # Solo incluir campos serializables
        error_dict = {
            "type": error.get("type"),
            "loc": list(error.get("loc", [])),
            "msg": error.get("msg"),
        }
        # NO incluir 'input' ya que puede contener FormData
        errors.append(error_dict)
    
    # Log del error
    logger.error(f"[VALIDATION ERROR] Request ID: {request.state.request_id} | {errors}")
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": errors,
            "request_id": request.state.request_id
        }
    )

async def generic_exception_handler(request: Request, exc: Exception):
    # Aquí puedes filtrar tipos de excepción si lo deseas
    print(f"[GENERIC ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {str(exc)}")
    error_detail = str(exc)
    if "Matrícula ya existe" in error_detail:
        return JSONResponse(
            status_code=400,
            content={"detail": error_detail, "request_id": getattr(request.state, "request_id", None)}
        )
    if "Credenciales inválidas" in error_detail:
        return JSONResponse(
            status_code=401,
            content={"detail": error_detail, "request_id": getattr(request.state, "request_id", None)}
        )
    # Error genérico
    return JSONResponse(
        status_code=500,
        content={"detail": "Error interno del servidor", "request_id": getattr(request.state, "request_id", None)}
    )