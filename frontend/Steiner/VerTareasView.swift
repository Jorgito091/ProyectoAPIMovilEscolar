import SwiftUI

struct VerTareasView: View {
    let accessToken: String
    let alumnoID: Int

    // Colores cálidos y oscuros estilo escolar
    let cafe = Color(red: 71/255, green: 53/255, blue: 37/255)
    let beige = Color(red: 230/255, green: 220/255, blue: 200/255)
    let cafeOscuro = Color(red: 51/255, green: 37/255, blue: 24/255)

    @State private var grupoID: String = ""
    @State private var tareas: [Tarea] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var selectedTarea: Tarea? = nil

    // Para picker de documentos
    @State private var showDocumentPicker = false
    @State private var tareaParaEntrega: Tarea? = nil
    @State private var selectedFileURL: URL? = nil
    @State private var uploadMessage: String = ""
    @State private var isUploading: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "number")
                    .foregroundColor(cafeOscuro)
                TextField("ID del Grupo", text: $grupoID)
                    .padding(10)
                    .background(beige.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(cafeOscuro)
            }
            .padding(.horizontal)

            Button(action: cargarTareas) {
                if isLoading {
                    ProgressView()
                        .tint(beige)
                } else {
                    Text("Ver tareas del grupo")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(beige)
                }
            }
            .padding(.vertical, 10)
            .background(cafe)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: cafeOscuro.opacity(0.08), radius: 4, y: 1)

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .padding()
            }

            List(tareas) { tarea in
                TareaItemView(
                    tarea: tarea,
                    onTap: { selectedTarea = tarea },
                    onUpload: {
                        tareaParaEntrega = tarea
                        showDocumentPicker = true
                    },
                    isUploading: isUploading && tareaParaEntrega?.id == tarea.id
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 2)
            }
            .sheet(item: $selectedTarea) { tarea in
                TareaDetalleView(tarea: tarea)
            }
            // Picker de archivos
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(fileURL: $selectedFileURL) { url in
                    // Cerrar el picker inmediatamente
                    showDocumentPicker = false
                    
                    // Procesar el archivo si fue seleccionado
                    if let tarea = tareaParaEntrega, let fileURL = url {
                        uploadMessage = "Preparando archivo..."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            subirEntrega(tarea: tarea, alumnoID: alumnoID, fileURL: fileURL)
                        }
                    } else if url == nil {
                        uploadMessage = "Selección cancelada"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            uploadMessage = ""
                        }
                    }
                    
                    // Resetear variables
                    selectedFileURL = nil
                    // tareaParaEntrega se mantiene hasta que termine la subida
                }
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .foregroundColor(cafe)
                    .padding()
            }
        }
        .padding(.vertical)
    }

    func cargarTareas() {
        guard let claseIdInt = Int(grupoID) else {
            mensaje = "ID de clase inválido"
            return
        }
        isLoading = true
        mensaje = ""
        tareas = []
        guard let url = URL(string: "http://localhost:8000/tareas/clase/\(claseIdInt)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // El endpoint /tareas/clase/{clase_id} no requiere autenticación
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos"
                    return
                }
                do {
                    let tareasDecodificadas = try JSONDecoder().decode([Tarea].self, from: data)
                    tareas = tareasDecodificadas
                    if tareas.isEmpty {
                        mensaje = "No hay tareas para esta clase"
                    }
                } catch {
                    mensaje = "Error al decodificar las tareas"
                }
            }
        }.resume()
    }

    func subirEntrega(tarea: Tarea, alumnoID: Int, fileURL: URL) {
        isUploading = true
        uploadMessage = "Subiendo archivo..."
        
        // Verificar que el archivo existe y se puede leer
        guard fileURL.startAccessingSecurityScopedResource() else {
            isUploading = false
            uploadMessage = "No se pudo acceder al archivo."
            return
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            isUploading = false
            uploadMessage = "No se pudo leer el archivo."
            return
        }
        
        // Determinar MIME type basado en extensión
        let fileName = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()
        let mimeType: String
        switch fileExtension {
        case "pdf":
            mimeType = "application/pdf"
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
        case "png":
            mimeType = "image/png"
        case "gif":
            mimeType = "image/gif"
        case "txt":
            mimeType = "text/plain"
        case "rtf":
            mimeType = "application/rtf"
        case "doc":
            mimeType = "application/msword"
        case "docx":
            mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xlsx":
            mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "pptx":
            mimeType = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        default:
            mimeType = "application/octet-stream"
        }
        
        // Crear multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        // Agregar el archivo
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Cerrar boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        guard let url = URL(string: "http://localhost:8000/entregas/tarea/\(tarea.id)") else {
            isUploading = false
            uploadMessage = "URL incorrecta para la entrega."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        request.timeoutInterval = 60 // 60 segundos timeout
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
                if let error = error {
                    uploadMessage = "Error al subir: \(error.localizedDescription)"
                    tareaParaEntrega = nil
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    uploadMessage = "Sin respuesta del servidor"
                    tareaParaEntrega = nil
                    return
                }
                
                if httpResponse.statusCode == 201 {
                    uploadMessage = "¡Entrega subida exitosamente!"
                    // Limpiar después de 3 segundos
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        uploadMessage = ""
                    }
                } else {
                    if let data = data, let serverMsg = String(data: data, encoding: .utf8) {
                        uploadMessage = "Error (\(httpResponse.statusCode)): \(serverMsg)"
                    } else {
                        uploadMessage = "Error: Código \(httpResponse.statusCode)"
                    }
                }
                
                // Resetear variables de estado
                tareaParaEntrega = nil
            }
        }.resume()
    }
}
