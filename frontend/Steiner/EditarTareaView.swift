import SwiftUI

struct EditarTareaView: View {
    let accessToken: String
    var onTareaEditada: (() -> Void)? = nil

    @State private var tareaID: String = ""
    @State private var nuevoTitulo: String = ""
    @State private var nuevaDescripcion: String = ""
    @State private var nuevaFechaInicio: Date = Date()
    @State private var nuevaFechaEntrega: Date = Date()
    @State private var editarFechaInicio = false
    @State private var editarFechaEntrega = false
    @State private var mensaje = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            TextField("ID de la tarea a editar", text: $tareaID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Nuevo título", text: $nuevoTitulo)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Nueva descripción", text: $nuevaDescripcion)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Toggle("Editar fecha de inicio", isOn: $editarFechaInicio)
                .padding(.horizontal)
            if editarFechaInicio {
                DatePicker("Nueva fecha de inicio", selection: $nuevaFechaInicio, displayedComponents: .date)
                    .padding(.horizontal)
            }
            Toggle("Editar fecha de entrega", isOn: $editarFechaEntrega)
                .padding(.horizontal)
            if editarFechaEntrega {
                DatePicker("Nueva fecha de entrega", selection: $nuevaFechaEntrega, displayedComponents: .date)
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

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.orange)
                    .padding()
            }
        }
    }

    func editarTarea() {
        guard let tareaIdInt = Int(tareaID) else {
            mensaje = "ID de tarea inválido"
            return
        }
        isLoading = true
        mensaje = ""

        var updateData: [String: Any] = [:]
        if !nuevoTitulo.isEmpty { updateData["titulo"] = nuevoTitulo }
        if !nuevaDescripcion.isEmpty { updateData["descripcion"] = nuevaDescripcion }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        if editarFechaInicio { updateData["fecha_inicio"] = formatter.string(from: nuevaFechaInicio) }
        if editarFechaEntrega { updateData["fecha_entrega"] = formatter.string(from: nuevaFechaEntrega) }
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
        guard let url = URL(string: "http://localhost:8000/tareas/\(tareaIdInt)") else {
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
                    tareaID = ""
                    nuevoTitulo = ""
                    nuevaDescripcion = ""
                    editarFechaInicio = false
                    editarFechaEntrega = false
                    onTareaEditada?()
                } else {
                    mensaje = "Error al actualizar (\(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}
