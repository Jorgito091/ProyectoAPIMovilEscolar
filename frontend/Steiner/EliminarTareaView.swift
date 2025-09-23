import SwiftUI

struct EliminarTareaView: View {
    let accessToken: String
    var onTareaEliminada: (() -> Void)? = nil

    @State private var tareaID: String = ""
    @State private var mensaje = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            TextField("ID de la tarea a eliminar", text: $tareaID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button(action: eliminarTarea) {
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
            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    func eliminarTarea() {
        guard let tareaIdInt = Int(tareaID) else {
            mensaje = "ID de tarea inválido"
            return
        }
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/tareas/\(tareaIdInt)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

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
                    mensaje = "¡Tarea eliminada!"
                    tareaID = ""
                    onTareaEliminada?()
                } else {
                    mensaje = "Error al eliminar (\(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}
