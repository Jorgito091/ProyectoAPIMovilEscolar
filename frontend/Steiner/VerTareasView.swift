import SwiftUI

struct VerTareasView: View {
    let accessToken: String

    @State private var grupoID: String = ""
    @State private var tareas: [Tarea] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var selectedTarea: Tarea? = nil

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
                TareaItemView(tarea: tarea, onTap: { selectedTarea = tarea })
            }
            .sheet(item: $selectedTarea) { tarea in
                TareaDetalleView(tarea: tarea)
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
}
