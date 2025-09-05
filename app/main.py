# app/main.py
from fastapi import FastAPI
from app.database import Base, engine
from app.routers import alumno_router, tarea_router

# Crear tablas si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(title="API Escolar Modularizada", version="1.0")

# Registrar routers
app.include_router(alumno_router.router)
app.include_router(tarea_router.router)