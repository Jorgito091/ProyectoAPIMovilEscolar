import SwiftUI

struct CrearTareaView: View {
    let accessToken: String
    let userID: Int  
    var onTareaCreada: (() -> Void)? = nil

    @State private var titulo: String = ""
    @State private var descripcion: String = ""
    @State private var fechaLimite: Date = Date()
    @State private var usarFechaLimite = false
    @State private var isLoading = false
    @State private var mensaje = ""
    @State private var success: Bool? = nil

    // Estados para clases y picker
    @State private var clases: [Clase] = []
    @State private var claseSeleccionada: Clase? = nil

    var body: some View {
        VStack {
            TextField("Título", text: $titulo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Descripción", text: $descripcion)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if clases.isEmpty {
                ProgressView("Cargando clases...")
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading) {
                    Text("Selecciona la clase:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    Picker("Clase", selection: $claseSeleccionada) {
                        ForEach(clases, id: \.self) { clase in
                            Text(clase.nombre ?? "Clase \(clase.id)").tag(clase as Clase?)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .padding(.horizontal)
                }
            }

            Toggle("Fecha límite", isOn: $usarFechaLimite)
                .padding(.horizontal)
            if usarFechaLimite {
                DatePicker("Fecha límite", selection: $fechaLimite, displayedComponents: .date)
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
        .onAppear { cargarClasesImpartidas() }
    }

    func cargarClasesImpartidas() {
        guard let url = URL(string: "http://localhost:8000/user/\(userID)") else {
            mensaje = "URL de usuario incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let detalle = try? JSONDecoder().decode(UsuarioDetalle.self, from: data),
                   let clasesImpartidas = detalle.clases_impartidas {
                    self.clases = clasesImpartidas
                    if let first = clasesImpartidas.first {
                        claseSeleccionada = first
                    }
                } else {
                    mensaje = "No se pudieron obtener las clases del usuario"
                }
            }
        }.resume()
    }

    func crearTarea() {
        guard let clase = claseSeleccionada, !titulo.isEmpty else {
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
            "clase_id": clase.id
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if usarFechaLimite { tareaData["fecha_limite"] = formatter.string(from: fechaLimite) }

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
                    claseSeleccionada = clases.first
                    usarFechaLimite = false
                    onTareaCreada?()
                } else {
                    mensaje = "Error al crear la tarea (\(httpResponse.statusCode))"
                    success = false
                }
            }
        }.resume()
    }
}
