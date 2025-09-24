import SwiftUI

struct VerTareasView: View {
    let accessToken: String
    let alumnoID: Int  // <-- Agrega aquí el ID del alumno logueado

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

    var body: some View {
        VStack {
            TextField("ID del Grupo", text: $grupoID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button(action: cargarTareas) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Ver tareas del grupo").frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.green.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .padding()
            }
            List(tareas) { tarea in
                VStack(alignment: .leading) {
                    TareaItemView(tarea: tarea, onTap: { selectedTarea = tarea })
                    Button("Subir entrega") {
                        tareaParaEntrega = tarea
                        showDocumentPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
                }
            }
            .sheet(item: $selectedTarea) { tarea in
                TareaDetalleView(tarea: tarea)
            }
            // Picker de archivos
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(fileURL: $selectedFileURL) { url in
                    if let tarea = tareaParaEntrega, let fileURL = url {
                        subirEntrega(tarea: tarea, alumnoID: alumnoID, fileURL: fileURL)
                    }
                }
            }
            if !uploadMessage.isEmpty {
                Text(uploadMessage)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }

    func cargarTareas() {
        guard let grupoIdInt = Int(grupoID) else {
            mensaje = "ID de grupo inválido"
            return
        }
        isLoading = true
        mensaje = ""
        tareas = []
        guard let url = URL(string: "http://localhost:8000/tareas/grupo/\(grupoIdInt)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
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
                        mensaje = "No hay tareas para este grupo"
                    }
                } catch {
                    mensaje = "Error al decodificar las tareas"
                }
            }
        }.resume()
    }

    func subirEntrega(tarea: Tarea, alumnoID: Int, fileURL: URL) {
        uploadMessage = ""
        // 1. Lee el archivo
        guard let fileData = try? Data(contentsOf: fileURL) else {
            uploadMessage = "No se pudo leer el archivo."
            return
        }
        // 2. Prepara request para backend (ajusta la URL a tu endpoint real)
        guard let url = URL(string: "http://localhost:8000/entregas/archivo/") else {
            uploadMessage = "URL incorrecta para la entrega."
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // 3. Construye el body multipart con tarea_id, alumno_id y archivo
        var body = Data()
        // tarea_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tarea_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tarea.id)\r\n".data(using: .utf8)!)
        // alumno_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"alumno_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(alumnoID)\r\n".data(using: .utf8)!)
        // archivo
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"archivo\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        // end
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        // 4. Envía request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    uploadMessage = "Error al subir: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    uploadMessage = "Sin respuesta del servidor"
                    return
                }
                if httpResponse.statusCode == 201 {
                    uploadMessage = "¡Entrega subida exitosamente!"
                } else {
                    // Intenta mostrar el error de la respuesta, si hay
                    if let data = data, let serverMsg = String(data: data, encoding: .utf8) {
                        uploadMessage = "Error (\(httpResponse.statusCode)): \(serverMsg)"
                    } else {
                        uploadMessage = "Error: Código \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}
