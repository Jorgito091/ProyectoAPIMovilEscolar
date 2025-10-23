import SwiftUI

// Vista de asistencias para el maestro
struct AsisView: View {
    let accessToken: String
    let userID: Int

    @State private var clases: [Clase] = []
    @State private var alumnosPorClase: [Int: [UsuarioSimple]] = [:]
    @State private var asistenciaEstado: [Int: [Int: Bool]] = [:] // [idClase: [idAlumno: present]]
    @State private var selectedClaseId: Int? = nil
    @State private var selectedFecha: Date = Date()
    @State private var tema: String = ""
    
    @State private var isLoading = false
    @State private var mensaje: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button("Cerrar") { dismiss() }
                    .padding(.top, 8)
                    .foregroundColor(.red)
            }

            Text("Registro de Asistencias")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.purple)

            // Clase picker
            Picker("Clase", selection: Binding(get: { selectedClaseId }, set: { newId in
                selectedClaseId = newId
                if let id = newId { cargarAlumnos(claseId: id) }
            })) {
                Text("Selecciona").tag(Optional<Int>(nil))
                ForEach(clases) { c in
                    Text(c.nombre ?? "Clase \(c.id)").tag(Optional(c.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)

            DatePicker("Fecha", selection: $selectedFecha, displayedComponents: .date)
                .padding(.horizontal)

            TextField("Tema de la clase (opcional)", text: $tema)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if isLoading {
                ProgressView("Cargando...")
            } else if !mensaje.isEmpty {
                Text(mensaje).foregroundColor(.red).padding(.horizontal)
            }

            if let claseId = selectedClaseId, let alumnos = alumnosPorClase[claseId] {
                List(alumnos, id: \.id) { alumno in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(alumno.nombre).font(.headline)
                            Text("ID: \(alumno.id)").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            marcarPresente(claseId: claseId, alumnoId: alumno.id, presente: true)
                        } label: {
                            Image(systemName: asistenciaEstado[claseId]?[alumno.id] == true ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Button {
                            marcarPresente(claseId: claseId, alumnoId: alumno.id, presente: false)
                        } label: {
                            Image(systemName: asistenciaEstado[claseId]?[alumno.id] == false ? "xmark.circle.fill" : "circle")
                                .foregroundColor(.red)
                                .font(.title2)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(InsetGroupedListStyle())
                .frame(maxHeight: 350)
            } else {
                Text("Selecciona una clase para ver alumnos.")
                    .foregroundColor(.gray)
                    .padding()
            }

            Button {
                guardarAsistencias()
            } label: {
                Text("Guardar Asistencias")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear(perform: cargarClases)
    }

    // MARK: - Helpers / Networking

    func iso8601String(from date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime] // evita fracciones para máxima compatibilidad
        return fmt.string(from: date)
    }

    func cargarClases() {
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/clases") else {
            mensaje = "URL incorrecta para clases"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    mensaje = "Error cargando clases: \(err.localizedDescription)"
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos de clases"
                    return
                }
                do {
                    self.clases = try JSONDecoder().decode([Clase].self, from: data)
                    if self.clases.isEmpty { self.mensaje = "No hay clases." }
                    else {
                        if self.selectedClaseId == nil {
                            self.selectedClaseId = self.clases.first?.id
                            if let id = self.selectedClaseId { cargarAlumnos(claseId: id) }
                        }
                    }
                } catch {
                    mensaje = "Error al decodificar clases: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func cargarAlumnos(claseId: Int) {
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/clases/\(claseId)/alumnos") else {
            mensaje = "URL incorrecta para alumnos"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, err in
            DispatchQueue.main.async {
                isLoading = false
                if let err = err {
                    mensaje = "Error cargando alumnos: \(err.localizedDescription)"
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos de alumnos"
                    return
                }
                do {
                    let alumnos = try JSONDecoder().decode([UsuarioSimple].self, from: data)
                    self.alumnosPorClase[claseId] = alumnos
                    var estado: [Int: Bool] = self.asistenciaEstado[claseId] ?? [:]
                    for a in alumnos {
                        if estado[a.id] == nil { estado[a.id] = false }
                    }
                    self.asistenciaEstado[claseId] = estado
                } catch {
                    mensaje = "Error al decodificar alumnos: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func marcarPresente(claseId: Int, alumnoId: Int, presente: Bool) {
        var estado = asistenciaEstado[claseId] ?? [:]
        estado[alumnoId] = presente
        asistenciaEstado[claseId] = estado
    }

    func guardarAsistencias() {
        guard let claseId = selectedClaseId else {
            mensaje = "Selecciona una clase"
            return
        }
        guard let alumnos = alumnosPorClase[claseId], !alumnos.isEmpty else {
            mensaje = "No hay alumnos para esta clase"
            return
        }

        isLoading = true
        mensaje = ""

        let fechaStr = iso8601String(from: selectedFecha)
        let temaFinal = tema.isEmpty ? "Clase \(fechaStr)" : tema

        let alumnosPresentes = alumnos.filter { asistenciaEstado[claseId]?[$0.id] == true }

        if alumnosPresentes.isEmpty {
            isLoading = false
            mensaje = "Marca al menos un alumno como presente"
            return
        }

        let group = DispatchGroup()
        var errores: [String] = []

        for alumno in alumnosPresentes {
            group.enter()
            guard let url = URL(string: "http://localhost:8000/asistencias/") else {
                errores.append("URL inválida para crear asistencia")
                group.leave()
                continue
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let dict: [String: Any] = [
                "tema": temaFinal,
                "fecha_clase": fechaStr,
                "id_clase": claseId,
                "id_alumno": alumno.id
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: dict, options: [])

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        errores.append("Alumno \(alumno.nombre): \(error.localizedDescription)")
                        group.leave()
                        return
                    }
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        errores.append("Alumno \(alumno.nombre): status \(http.statusCode) - \(body)")
                    }
                    group.leave()
                }
            }.resume()
        }

        group.notify(queue: .main) {
            isLoading = false
            if errores.isEmpty {
                mensaje = "Asistencias guardadas correctamente"
            } else {
                mensaje = "Algunas asistencias fallaron:\n" + errores.joined(separator: "\n")
            }
        }
    }
}
