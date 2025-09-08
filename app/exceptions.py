
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
    # Log en terminal
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

    print(f"[GENERIC ERROR] Request ID: {getattr(request.state, 'request_id', None)} | {str(exc)}")
    
    return JSONResponse(
        status_code=500,
        content={"detail": "Error interno del servidor", "request_id": getattr(request.state, "request_id", None)}
    )