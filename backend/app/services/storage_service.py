import os
import uuid
from fastapi import HTTPException, UploadFile, status
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

class StorageService:
    def __init__(self):
        url: str = os.getenv("SUPABASE_URL")
        key: str = os.getenv("SUPABASE_KEY")

        if not url or not key:
            raise ValueError("Las variables de entorno de Supabase no están configuradas.")
            
        self.client: Client = create_client(url, key)
        self.bucket_name: str = "entregas"

    def sanitize_filename(self, filename: str) -> str:
        """
        Limpia el nombre del archivo para que sea compatible con Supabase Storage.
        """
        import re
        # Remover caracteres especiales y espacios
        # Mantener solo letras, números, puntos, guiones y guiones bajos
        sanitized = re.sub(r'[^a-zA-Z0-9._-]', '_', filename)
        # Remover múltiples guiones bajos consecutivos
        sanitized = re.sub(r'_+', '_', sanitized)
        # Remover guiones bajos al inicio y final
        sanitized = sanitized.strip('_')
        # Asegurar que no esté vacío
        if not sanitized:
            sanitized = "archivo"
        return sanitized
    
    def sanitize_user_name(self, user_name: str) -> str:
        """
        Limpia el nombre del usuario para usar en rutas.
        """
        import re
        # Solo mantener caracteres alfanuméricos
        sanitized = re.sub(r'[^a-zA-Z0-9]', '', user_name)
        # Limitar longitud
        sanitized = sanitized[:20] if sanitized else "usuario"
        return sanitized

    async def upload_file(self, file: UploadFile, user_name: str) -> str:
        """
        Sube un archivo a Supabase Storage y devuelve la ruta de almacenamiento.
        """
        try:
            contents = await file.read()
            
            # Limpiar nombres para Supabase
            clean_user_name = self.sanitize_user_name(user_name)
            clean_filename = self.sanitize_filename(file.filename or "archivo.bin")
            
            file_path = f"entregas-usuario-{clean_user_name}/{uuid.uuid4()}-{clean_filename}"

            # Usar MIME types más genéricos para compatibilidad con Supabase
            allowed_mime_types = {
                'application/pdf',
                'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
                'text/plain'
            }
            
            # Si el MIME type no está en la lista permitida, usar genérico
            content_type = file.content_type if file.content_type in allowed_mime_types else 'application/octet-stream'
            
            print(f"[STORAGE] Uploading file: {clean_filename}")
            print(f"[STORAGE] Original MIME: {file.content_type}")
            print(f"[STORAGE] Using MIME: {content_type}")
            print(f"[STORAGE] File size: {len(contents)} bytes")
            
            self.client.storage.from_(self.bucket_name).upload(
                path=file_path,
                file=contents,
                file_options={"content-type": content_type}
            )
            
            return file_path
        
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"No se pudo subir el archivo: {e}"
            )
