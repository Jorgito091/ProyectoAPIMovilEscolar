# app/main.py
from fastapi import FastAPI
from app.database import Base, engine
from app.routers import alumno_router, tarea_router
from app.middlewares.request_context import request_context_middleware
from app.middlewares.auth import auth_middleware

Base.metadata.create_all(bind=engine)

app = FastAPI(title="API Escolar Modularizada", version="1.0")

# Registrar middlewares
app.middleware("http")(request_context_middleware)
# app.middleware("http")(auth_middleware)  # activar solo si quieres auth global

# Routers
app.include_router(alumno_router.router)
app.include_router(tarea_router.router)