import SwiftUI

struct VerTareasMaestroView: View {
    let accessToken: String
    let userID: Int

    @State private var clases: [Clase] = []
    @State private var selectedClase: Clase? = nil
    @State private var tareas: [TareaOut] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false

  
    @State private var tareaSeleccionada: TareaOut? = nil
    @State private var accion: AccionTarea? = nil

    enum AccionTarea: Identifiable {
        case checar, editar, eliminar
        var id: Int { hashValue }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Picker de clases/materias
            if clases.isEmpty {
                ProgressView("Cargando materias...")
                    .onAppear { cargarMateriasDeMaestro() }
            } else {
                // Reemplaza el Picker problemático por este bloque:
                Picker("Selecciona una materia", selection: $selectedClase) {
                    ForEach(clases, id: \.self) { clase in
                        Text(clase.nombre ?? "Clase \(clase.id)")
                            .tag(Optional(clase)) // selection es Clase?
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(10)
                .padding(.top, 8)
            }

            // Lista de tareas
            if let _ = selectedClase {
                if isLoading {
                    ProgressView("Cargando tareas...")
                } else if tareas.isEmpty {
                    Text(mensaje.isEmpty ? "No hay tareas para esta materia." : mensaje)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(tareas) { tarea in
                        HStack {
                            Text(tarea.titulo)
                                .font(.headline)
                            Spacer()
                            Menu {
                                Button("Checar", systemImage: "doc.text.magnifyingglass") {
                                    tareaSeleccionada = tarea
                                    accion = .checar
                                }
                                Button("Editar", systemImage: "pencil") {
                                    tareaSeleccionada = tarea
                                    accion = .editar
                                }
                                Button("Eliminar", systemImage: "trash", role: .destructive) {
                                    tareaSeleccionada = tarea
                                    accion = .eliminar
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                Text("Selecciona una materia para ver las tareas.")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical)
        .onChange(of: selectedClase) { clase in
            mensaje = ""
            tareas = []
            isLoading = true
            if let clase = clase {
                cargarTareas(claseID: clase.id)
            } else {
                isLoading = false
            }
        }
        // Sheet para cada acción sobre la tarea seleccionada
        .sheet(item: $accion) { accion in
            switch accion {
            case .checar:
                if let tarea = tareaSeleccionada {
                    CalTareaView(accessToken: accessToken, tareaID: tarea.id)
                }
            case .editar:
                if let tarea = tareaSeleccionada {
                    EditarTareaView(accessToken: accessToken, userID: userID, tareaID: tarea.id)
                }
            case .eliminar:
                if let tarea = tareaSeleccionada {
                    EliminarTareaView(accessToken: accessToken, userID: userID)
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
}

