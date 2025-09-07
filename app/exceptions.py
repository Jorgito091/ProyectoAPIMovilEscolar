# app/exceptions.py
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "request_id": getattr(request.state, "request_id", None)}
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "detail": exc.errors(),
            "body": exc.body,
            "request_id": getattr(request.state, "request_id", None)
        }
    )

async def generic_exception_handler(request: Request, exc: Exception):
    # Aquí puedes hacer logging global
    print(f"[ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Error interno del servidor", "request_id": getattr(request.state, "request_id", None)}
    )