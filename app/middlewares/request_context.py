# app/middlewares/request_context.py
import time, uuid
from fastapi import Request

async def request_context_middleware(request: Request, call_next):
    # Atributos personalizados
    request.state.request_id = str(uuid.uuid4())
    request.state.start_time = time.time()
    request.state.client_ip = request.client.host

    # Procesar la petición
    response = await call_next(request)

    # Añadir headers extra
    process_time = time.time() - request.state.start_time
    response.headers["X-Process-Time"] = f"{process_time:.4f}s"
    response.headers["X-Request-ID"] = request.state.request_id

    return response