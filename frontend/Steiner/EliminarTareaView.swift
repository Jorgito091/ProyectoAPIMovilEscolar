import SwiftUI

struct EliminarTareaView: View {
    let accessToken: String
    let userID: Int
    var onTareaEliminada: (() -> Void)? = nil
    let tareaID: Int


    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""
    @State private var mostrarExito = false

    @State private var clases: [Clase] = []
    @State private var selectedClase: Clase? = nil
    @State private var tareas: [TareaOut] = []
    @State private var tareaSeleccionada: TareaOut? = nil

    @State private var mensaje = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            if mostrarExito {
                Text("¡Tarea eliminada!")
                    .foregroundColor(.green)
                    .bold()
                    .padding(.top, 8)
            }

            // Picker de clases
            if clases.isEmpty {
                ProgressView("Cargando materias...")
                    .onAppear { cargarMateriasDeMaestro() }
            } else {
                Picker("Selecciona una materia", selection: $selectedClase) {
                    ForEach(clases, id: \.self) { clase in
                        Text(clase.nombre).tag(clase as Clase?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(10)
                .padding(.top, 8)
            }

            // Picker de tareas
            if let _ = selectedClase {
                if isLoading {
                    ProgressView("Cargando tareas...")
                } else if tareas.isEmpty {
                    Text(mensaje.isEmpty ? "No hay tareas para esta materia." : mensaje)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Picker("Selecciona la tarea a eliminar", selection: $tareaSeleccionada) {
                        ForEach(tareas, id: \.self) { tarea in
                            Text(tarea.titulo).tag(tarea as TareaOut?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }
            }

            // Botón para eliminar
            if let tarea = tareaSeleccionada {
                Button(action: { eliminarTarea(tareaId: tarea.id) }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Eliminar tarea").bold().frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
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
        .alert(isPresented: $mostrarAlerta) {
            Alert(
                title: Text("Aviso"),
                message: Text(mensajeAlerta),
                dismissButton: .default(Text("Cerrar"))
            )
        }
    }

    // Cargar clases que imparte el maestro
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

    // Cargar tareas de la clase seleccionada
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

    // Eliminar tarea con manejo de errores y alerta amigable
    func eliminarTarea(tareaId: Int) {
        isLoading = true
        mensaje = ""
        mostrarExito = false

        guard let url = URL(string: "http://127.0.0.1:8000/tareas/\(tareaId)") else {
            mensajeAlerta = "URL incorrecta"
            mostrarAlerta = true
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensajeAlerta = "Error de red: \(error.localizedDescription)"
                    mostrarAlerta = true
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    mensajeAlerta = "Sin respuesta del servidor"
                    mostrarAlerta = true
                    return
                }
                if httpResponse.statusCode == 200 {
                    mostrarExito = true
                    tareaSeleccionada = nil
                    tareas.removeAll(where: { $0.id == tareaId })
                    onTareaEliminada?()
                } else if httpResponse.statusCode == 409 || httpResponse.statusCode == 400 {
                   
                    if let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let detail = json["detail"] as? String {
                        mensajeAlerta = detail
                    } else {
                        mensajeAlerta = "No se puede eliminar esta tarea porque tiene entregas asociadas.\nY no hay presupuesto para pagar a sistemas asi que ni modo :C."
                    }
                    mostrarAlerta = true
                } else {
                    mensajeAlerta = "No se puede master , alguien ya subio y no hay presupuesto para eso , te me cuidas (\(httpResponse.statusCode))."
                    mostrarAlerta = true
                }
            }
        }.resume()
    }
}

