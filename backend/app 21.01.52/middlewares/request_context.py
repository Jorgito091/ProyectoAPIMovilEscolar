# app/middlewares/request_context.py
import time, uuid
from fastapi import Request

async def request_context_middleware(request: Request, call_next):
      request.state.request_id = str(uuid.uuid4())
      request.state.start_time = time.time()
      request.state.client_ip = request.client.host

      response = await call_next(request)

      process_time = time.time() - request.state.start_time
      response.headers["X-Process-Time"] = f"{process_time:.4f}s"
      response.headers["X-Request-ID"] = request.state.request_id

      # Log automático para todas las peticiones
      print(f"[DEBUG] Request ID: {request.state.request_id} | "
            f"Path: {request.url.path} | "
            f"Method: {request.method} | "
            f"IP: {request.state.client_ip} | "
            f"Tiempo: {process_time:.4f}s")

      return response