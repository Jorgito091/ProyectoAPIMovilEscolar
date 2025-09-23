import SwiftUI

struct CrearTareaView: View {
    let accessToken: String
    var onTareaCreada: (() -> Void)? = nil

    @State private var titulo: String = ""
    @State private var descripcion: String = ""
    @State private var grupoID: String = ""
    @State private var fechaInicio: Date = Date()
    @State private var fechaEntrega: Date = Date()
    @State private var usarFechaInicio = false
    @State private var usarFechaEntrega = false
    @State private var isLoading = false
    @State private var mensaje = ""
    @State private var success: Bool? = nil

    var body: some View {
        VStack {
            TextField("Título", text: $titulo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Descripción", text: $descripcion)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("ID del Grupo", text: $grupoID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Toggle("Fecha de inicio", isOn: $usarFechaInicio)
                .padding(.horizontal)
            if usarFechaInicio {
                DatePicker("Fecha de inicio", selection: $fechaInicio, displayedComponents: .date)
                    .padding(.horizontal)
            }
            Toggle("Fecha de entrega", isOn: $usarFechaEntrega)
                .padding(.horizontal)
            if usarFechaEntrega {
                DatePicker("Fecha de entrega", selection: $fechaEntrega, displayedComponents: .date)
                    .padding(.horizontal)
            }
            Button(action: crearTarea) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Crear tarea").bold().frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)

            if let success = success {
                Text(success ? "¡Tarea creada exitosamente!" : mensaje)
                    .foregroundColor(success ? .green : .red)
                    .padding()
            } else if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    func crearTarea() {
        guard let grupoIdInt = Int(grupoID), !titulo.isEmpty else {
            mensaje = "Completa todos los campos obligatorios"
            success = false
            return
        }
        isLoading = true
        mensaje = ""
        success = nil

        var tareaData: [String: Any] = [
            "titulo": titulo,
            "descripcion": descripcion,
            "grupo_id": grupoIdInt
        ]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if usarFechaInicio { tareaData["fecha_inicio"] = formatter.string(from: fechaInicio) }
        if usarFechaEntrega { tareaData["fecha_entrega"] = formatter.string(from: fechaEntrega) }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: tareaData) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            success = false
            return
        }

        guard let url = URL(string: "http://localhost:8000/tareas/") else {
            mensaje = "URL incorrecta"
            isLoading = false
            success = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    success = false
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    mensaje = "Sin respuesta"
                    success = false
                    return
                }
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    success = true
                    mensaje = ""
                    titulo = ""
                    descripcion = ""
                    grupoID = ""
                    usarFechaInicio = false
                    usarFechaEntrega = false
                    onTareaCreada?()
                } else {
                    mensaje = "Error al crear la tarea (\(httpResponse.statusCode))"
                    success = false
                }
            }
        }.resume()
    }
}
