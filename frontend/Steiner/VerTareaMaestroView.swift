import SwiftUI

struct Maestro: Identifiable, Decodable {
    let id: Int
    let nombre: String
    let clases_impartidas: [Clase]
}


struct VerTareasMaestroView: View {
    let accessToken: String
    let userID: Int

    @State private var clases: [Clase] = []
    @State private var selectedClase: Clase? = nil
    @State private var tareas: [TareaOut] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var tareaSeleccionada: TareaOut? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Picker de clases/materias
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

            // Mostrar tareas o mensaje según materia
            if let clase = selectedClase {
                if isLoading {
                    ProgressView("Cargando tareas...")
                } else if tareas.isEmpty {
                    Text(mensaje.isEmpty ? "No hay tareas para esta materia." : mensaje)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    List(tareas) { tarea in
                        Button(action: { tareaSeleccionada = tarea }) {
                            HStack {
                                Text(tarea.titulo)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
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
        .sheet(item: $tareaSeleccionada) { tarea in
            CalTareaView(
                accessToken: accessToken,
                tareaID: tarea.id
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
