import SwiftUI

struct VerTareasView: View {
    let accessToken: String
    let alumnoID: Int
    let grupoID: Int?

    // Paleta tinto
    let tintoPrincipal = Color(red: 117/255, green: 22/255, blue: 46/255)
    let tintoClaro = Color(red: 170/255, green: 36/255, blue: 63/255)
    let blanco = Color.white

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

    // Token de carga para evitar sobrescribir resultados viejos
    @State private var cargaToken: UUID = UUID()

    var body: some View {
        VStack(spacing: 16) {
            if let grupoID = grupoID {
                if isLoading {
                    ProgressView("Cargando tareas...")
                        .tint(tintoPrincipal)
                } else if tareas.isEmpty {
                    Text(mensaje.isEmpty ? "Por el momento no hay tareas que hacer, haz algo en tu tiempo libre :D" : mensaje)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
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
                    .sheet(isPresented: $showDocumentPicker) {
                        DocumentPicker(fileURL: $selectedFileURL) { url in
                            showDocumentPicker = false
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
                            selectedFileURL = nil
                        }
                    }
                }
            } else {
                Text("Selecciona un grupo para ver las tareas.")
                    .foregroundColor(.gray)
            }

            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .foregroundColor(tintoPrincipal)
                    .padding()
            }
        }
        .padding(.vertical)
        .onChange(of: grupoID) { newGrupoID in
            cargaToken = UUID()
            tareas = []
            mensaje = ""
            isLoading = true
            if let gid = newGrupoID {
                cargarTareas(for: gid, token: cargaToken)
            } else {
                isLoading = false
            }
        }
        .onAppear {
            if let gid = grupoID, tareas.isEmpty {
                cargaToken = UUID()
                isLoading = true
                cargarTareas(for: gid, token: cargaToken)
            }
        }
    }

    func cargarTareas(for grupoId: Int, token: UUID) {
        guard let url = URL(string: "http://localhost:8000/tareas/clase/\(grupoId)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            tareas = []
            return
        }
        mensaje = ""
        tareas = []
        isLoading = true
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if token != cargaToken { return }
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    tareas = []
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos"
                    tareas = []
                    return
                }
                do {
                    let tareasDecodificadas = try JSONDecoder().decode([Tarea].self, from: data)
                    tareas = tareasDecodificadas
                    if tareas.isEmpty {
                        mensaje = "No hay tareas para este grupo"
                    }
                } catch {
                    mensaje = "Error al decodificar las tareas"
                    tareas = []
                }
            }
        }.resume()
    }

    func subirEntrega(tarea: Tarea, alumnoID: Int, fileURL: URL) {
        isUploading = true
        uploadMessage = "Subiendo archivo..."

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

        let fileName = fileURL.lastPathComponent
        let fileExtension = fileURL.pathExtension.lowercased()
        let mimeType: String
        switch fileExtension {
        case "pdf": mimeType = "application/pdf"
        case "jpg", "jpeg": mimeType = "image/jpeg"
        case "png": mimeType = "image/png"
        case "gif": mimeType = "image/gif"
        case "txt": mimeType = "text/plain"
        case "rtf": mimeType = "application/rtf"
        case "doc": mimeType = "application/msword"
        case "docx": mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xlsx": mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "pptx": mimeType = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        default: mimeType = "application/octet-stream"
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
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
        request.timeoutInterval = 60

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
                tareaParaEntrega = nil
            }
        }.resume()
    }
}
