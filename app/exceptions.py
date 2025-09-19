from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    print(f"[HTTP ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "request_id": getattr(request.state, "request_id", None)}
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    print(f"[VALIDATION ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {exc.errors()}")
    return JSONResponse(
        status_code=422,
        content={
            "detail": exc.errors(),
            "body": exc.body,
            "request_id": getattr(request.state, "request_id", None)
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