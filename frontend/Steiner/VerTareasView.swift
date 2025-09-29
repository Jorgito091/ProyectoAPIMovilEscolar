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
                VStack(alignment: .leading) {
                    TareaItemView(tarea: tarea, onTap: { selectedTarea = tarea })
                    Button("Subir entrega") {
                        tareaParaEntrega = tarea
                        showDocumentPicker = true
                    }
                    .font(.caption)
                    .foregroundColor(cafe)
                    .padding(.top, 2)
                }
                .listRowBackground(beige.opacity(0.7))
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
                    .foregroundColor(cafe)
                    .padding()
            }
        }
        .padding(.vertical)
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
        guard let fileData = try? Data(contentsOf: fileURL) else {
            uploadMessage = "No se pudo leer el archivo."
            return
        }
        guard let url = URL(string: "http://localhost:8000/entregas/archivo/") else {
            uploadMessage = "URL incorrecta para la entrega."
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tarea_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tarea.id)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"alumno_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(alumnoID)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"archivo\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

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
