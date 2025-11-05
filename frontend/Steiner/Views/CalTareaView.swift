import SwiftUI

struct CalTareaView: View {
    let accessToken: String
    let tareaID: Int

    @State private var entregas: [Entrega] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var entregaSeleccionada: Entrega? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Cerrar") {
                    dismiss()
                }
                .padding(.top, 8)
                .foregroundColor(.red)
            }
            if isLoading {
                ProgressView("Cargando entregas...")
            } else if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
            } else {
                List(entregas) { entrega in
                    Button(action: { entregaSeleccionada = entrega }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entrega.alumno.nombre)
                                    .font(.headline)
                                Text("Entregada: \(entrega.fecha_entrega)")
                                    .font(.subheadline)
                                if let calif = entrega.calificacion {
                                    Text("Calificación actual: \(calif, specifier: "%.2f")")
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            Image(systemName: "doc.circle")
                        }
                    }
                }
            }
        }
        .onAppear { cargarEntregas() }
        .sheet(item: $entregaSeleccionada) { entrega in
            CalSheet(
                accessToken: accessToken,
                entrega: entrega,
                onCalificar: { calif, comentarios in
                    actualizarEntrega(entregaId: entrega.id, calificacion: calif, comentarios: comentarios)
                }
            )
        }
    }

    func cargarEntregas() {
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/entregas/tarea/\(tareaID)") else {
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
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos"
                    return
                }
                do {
                    entregas = try JSONDecoder().decode([Entrega].self, from: data)
                    if entregas.isEmpty {
                        mensaje = "No hay entregas para esta tarea."
                    }
                } catch {
                    mensaje = "Error al decodificar entregas"
                }
            }
        }.resume()
    }

    func actualizarEntrega(entregaId: Int, calificacion: Float, comentarios: String) {
        guard let url = URL(string: "http://localhost:8000/entregas/\(entregaId)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let json: [String: Any] = [
            "calificacion": calificacion,
            "comentarios": comentarios
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    mensaje = "Error al calificar: \(error.localizedDescription)"
                    return
                }
                cargarEntregas()
            }
        }.resume()
    }
}
