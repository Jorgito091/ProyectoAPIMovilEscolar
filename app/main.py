from fastapi import FastAPI
from fastapi.security import OAuth2PasswordBearer
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.database import Base, engine
from app.routers import auth, tarea_router, user_router
from app.middlewares.request_context import request_context_middleware
from app.middlewares.auth import auth_middleware  

from app.exceptions import (
    http_exception_handler,
    validation_exception_handler,
    generic_exception_handler
)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="user/login")
# Crear tablas
Base.metadata.create_all(bind=engine)

# Instancia FastAPI
app = FastAPI(title="API Escolar Modularizada", version="1.0")

# Registro middleware
app.middleware("http")(request_context_middleware)
# app.middleware("http")(auth_middleware)  # activar si quieres auth global

# Registro excepciones
app.add_exception_handler(Exception, generic_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)

# Routers
app.include_router(user_router.router)
app.include_router(tarea_router.router)
app.include_router(auth.router)