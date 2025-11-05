import SwiftUI

struct EditarTareaView: View {
    let accessToken: String
    let userID: Int
    let tareaID: Int
    var onTareaEditada: (() -> Void)? = nil

    @State private var clases: [Clase] = []
    @State private var selectedClase: Clase? = nil
    @State private var tareas: [TareaOut] = []
    @State private var tareaSeleccionada: TareaOut? = nil

    @State private var nuevoTitulo: String = ""
    @State private var nuevaDescripcion: String = ""
    @State private var nuevaFechaLimite: Date = Date()
    @State private var editarFechaLimite = false
    @State private var mensaje = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            // Picker de clases
            if clases.isEmpty {
                ProgressView("Cargando materias...")
                    .onAppear { cargarMateriasDeMaestro() }
            } else {
                Picker("Selecciona una materia", selection: $selectedClase) {
                    ForEach(clases, id: \.self) { clase in
                        Text(clase.nombre ?? "Clase \(clase.id)").tag(clase as Clase?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(10)
                .padding(.top, 8)
            }

            // Picker de tareas
            if let clase = selectedClase {
                if isLoading {
                    ProgressView("Cargando tareas...")
                } else if tareas.isEmpty {
                    Text(mensaje.isEmpty ? "No hay tareas para esta materia." : mensaje)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Picker("Selecciona una tarea", selection: $tareaSeleccionada) {
                        ForEach(tareas, id: \.self) { tarea in
                            Text(tarea.titulo).tag(tarea as TareaOut?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
            }

            // Campos para editar tarea
            if let tarea = tareaSeleccionada {
                TextField("Nuevo título", text: $nuevoTitulo)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                TextField("Nueva descripción", text: $nuevaDescripcion)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Toggle("Editar fecha límite", isOn: $editarFechaLimite)
                    .padding(.horizontal)
                if editarFechaLimite {
                    DatePicker("Nueva fecha límite", selection: $nuevaFechaLimite, displayedComponents: .date)
                        .padding(.horizontal)
                }
                Button(action: editarTarea) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Editar tarea").bold().frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.orange)
                    .padding()
            }
        }
        .onChange(of: selectedClase) { clase in
            mensaje = ""
            tareas = []
            tareaSeleccionada = nil
            isLoading = true
            if let clase = clase {
                cargarTareas(claseID: clase.id)
            } else {
                isLoading = false
            }
        }
        .onChange(of: tareaSeleccionada) { tarea in
            if let tarea = tarea {
                nuevoTitulo = tarea.titulo
                nuevaDescripcion = tarea.descripcion ?? ""
                if let fechaLimiteStr = tarea.fecha_limite,
                   let fecha = ISO8601DateFormatter().date(from: fechaLimiteStr) {
                    nuevaFechaLimite = fecha
                    editarFechaLimite = true
                } else {
                    editarFechaLimite = false
                }
            }
        }
    }

    func cargarMateriasDeMaestro() {
        guard let url = URL(string: "http://127.0.0.1:8000/user/\(userID)") else {
            mensaje = "URL incorrecta para maestro"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data {
                    if let maestro = try? JSONDecoder().decode(Maestro.self, from: data) {
                        clases = maestro.clases_impartidas
                        if let primero = clases.first {
                            selectedClase = primero
                        }
                    } else {
                        mensaje = "Error al decodificar las materias"
                    }
                } else {
                    mensaje = "No se pudieron cargar las materias"
                }
            }
        }.resume()
    }

    func cargarTareas(claseID: Int) {
        isLoading = true
        mensaje = ""
        tareas = []
        guard let url = URL(string: "http://127.0.0.1:8000/tareas/clase/\(claseID)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    mensaje = "Error: \(err.localizedDescription)"
                    tareas = []
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos"
                    tareas = []
                    return
                }
                do {
                    tareas = try JSONDecoder().decode([TareaOut].self, from: data)
                    if tareas.isEmpty {
                        mensaje = "No hay tareas para esta materia."
                    }
                } catch {
                    mensaje = "Error al decodificar las tareas"
                    tareas = []
                }
            }
        }.resume()
    }

    func editarTarea() {
        guard let tarea = tareaSeleccionada else {
            mensaje = "Selecciona una tarea"
            return
        }
        isLoading = true
        mensaje = ""

        var updateData: [String: Any] = [:]
        if !nuevoTitulo.isEmpty { updateData["titulo"] = nuevoTitulo }
        if !nuevaDescripcion.isEmpty { updateData["descripcion"] = nuevaDescripcion }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if editarFechaLimite { updateData["fecha_limite"] = formatter.string(from: nuevaFechaLimite) }
        guard !updateData.isEmpty else {
            mensaje = "No hay ningún campo para actualizar"
            isLoading = false
            return
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: updateData) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            return
        }
        guard let url = URL(string: "http://127.0.0.1:8000/tareas/\(tarea.id)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    mensaje = "Sin respuesta"
                    return
                }
                if httpResponse.statusCode == 200 {
                    mensaje = "¡Tarea actualizada!"
                    onTareaEditada?()
                } else {
                    mensaje = "Error al actualizar (\(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}
