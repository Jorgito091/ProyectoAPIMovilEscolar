import SwiftUI
import CodeScanner


struct SignQRView: View {
    let accessToken: String
    let userID: Int

    @State private var isShowingScanner = false
    @State private var mensaje: String = ""
    @State private var isLoading = false

    @State private var alumnoIdEscaneado: Int? = nil
    @State private var alumnoNombre: String? = nil

    @State private var clases: [Clase] = []
    @State private var claseSeleccionada: Clase? = nil

    @State private var tareas: [TareaOut] = []
    @State private var tareaSeleccionadaId: Int? = nil

    // Fecha seleccionada para asistencia (ahora configurable)
    @State private var fechaSeleccionada: Date = Date()

    @State private var selectedMode: Mode = .inscribir

    // Sheets / navegaciones
    @State private var showAsisSheet = false
    @State private var showCalTareaSheet = false

    @Environment(\.dismiss) var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case inscribir
        case asistencia
        case revisar

        var id: String { self.rawValue }
        var title: String {
            switch self {
            case .inscribir: return "Inscribir"
            case .asistencia: return "Asistencia"
            case .revisar: return "Revisar"
            }
        }
    }

    private var tareaSeleccionada: TareaOut? {
        guard let id = tareaSeleccionadaId else { return nil }
        return tareas.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding(.trailing, 3)
            .padding(.top, 3)

            Text("Operaciones por QR")
                .font(.title2)
                .fontWeight(.bold)

            if alumnoIdEscaneado == nil {
                Button(action: { isShowingScanner = true }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 34, weight: .bold))
                        Text("Escanear QR")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(codeTypes: [.qr], completion: handleScan)
                }
            }

            if let alumnoId = alumnoIdEscaneado {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Alumno ID: \(alumnoId)").font(.headline)
                            if let nombre = alumnoNombre {
                                Text(nombre).font(.subheadline).foregroundColor(.blue)
                            } else {
                                Text("Buscando nombre...").font(.subheadline).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Button {
                            alumnoIdEscaneado = nil
                            alumnoNombre = nil
                        } label: {
                            Text("Cancelar").foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)

                    Picker("Acción", selection: $selectedMode) {
                        ForEach(Mode.allCases) { m in
                            Text(m.title).tag(m)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    Group {
                        switch selectedMode {
                        case .inscribir:
                            VStack(spacing: 10) {
                                if clases.isEmpty {
                                    ProgressView("Cargando clases...")
                                } else {
                                    Text("Selecciona clase para inscribir").font(.subheadline)
                                    Picker("Clase", selection: $claseSeleccionada) {
                                        ForEach(clases, id: \.self) { c in
                                            Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 120)

                                    Button("Inscribir") {
                                        guard let clase = claseSeleccionada else {
                                            mensaje = "Selecciona una clase."
                                            return
                                        }
                                        inscribirAlumno(alumno_id: alumnoId, clase_id: clase.id)
                                    }
                                    .buttonStyle(ActionButtonStyle(background: .blue))
                                }
                            }
                            .padding(.horizontal)

                        case .asistencia:
                            VStack(spacing: 10) {
                                if clases.isEmpty {
                                    ProgressView("Cargando clases...")
                                } else {
                                    Text("Selecciona clase y fecha").font(.subheadline)
                                    Picker("Clase", selection: $claseSeleccionada) {
                                        ForEach(clases, id: \.self) { c in
                                            Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 120)

                                    DatePicker("Fecha", selection: $fechaSeleccionada, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .padding(.horizontal)

                                    HStack(spacing: 10) {
                                        Button("Marcar asistencia rápida") {
                                            guard let clase = claseSeleccionada else {
                                                mensaje = "Selecciona una clase."
                                                return
                                            }
                                            marcarAsistenciaRapida(alumno_id: alumnoId, clase_id: clase.id, fecha: fechaSeleccionada)
                                        }
                                        .buttonStyle(ActionButtonStyle(background: .purple))

                                        Button("Abrir Asistencias") {
                                            showAsisSheet = true
                                        }
                                        .buttonStyle(ActionButtonStyle(background: .orange))
                                    }
                                }
                            }
                            .padding(.horizontal)

                        case .revisar:
                            VStack(spacing: 10) {
                                if tareas.isEmpty {
                                    ProgressView("Cargando tareas...")
                                } else {
                                    Text("Selecciona tarea").font(.subheadline)
                                    Picker("Tarea", selection: $tareaSeleccionadaId) {
                                        ForEach(tareas) { t in
                                            Text(t.titulo).tag(Optional(t.id))
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 120)

                                    HStack(spacing: 10) {
                                        Button("Marcar revisada") {
                                            guard let tarea = tareaSeleccionada else {
                                                mensaje = "Selecciona una tarea."
                                                return
                                            }
                                            marcarTareaRevisada(alumno_id: alumnoId, assignment_id: tarea.id)
                                        }
                                        .buttonStyle(ActionButtonStyle(background: .mint))

                                        Button("Abrir calificar") {
                                            guard tareaSeleccionada != nil else {
                                                mensaje = "Selecciona una tarea."
                                                return
                                            }
                                            showCalTareaSheet = true
                                        }
                                        .buttonStyle(ActionButtonStyle(background: .blue))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .onAppear {
                    alumnoNombre = nil
                    buscarAlumno(id: alumnoId)
                    cargarClasesImpartidas()
                    if selectedMode == .revisar { cargarTareasParaProfesor() }
                }
            } // if alumno

            if isLoading {
                ProgressView().padding()
            }

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(mensaje.lowercased().contains("éxito") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .sheet(isPresented: $showAsisSheet) {
            AsisView(accessToken: accessToken, userID: userID)
        }
        .sheet(isPresented: $showCalTareaSheet) {
            if let tarea = tareaSeleccionada {
                CalTareaView(accessToken: accessToken, tareaID: tarea.id)
            } else {
                Text("No se seleccionó tarea")
            }
        }
    }

    // MARK: - Escaneo
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let scan):
            let contenido = scan.string
            var alumnoId: Int?

            if let data = contenido.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let aid = json["alumno_id"] as? Int {
                alumnoId = aid
            } else if let aid = Int(contenido) {
                alumnoId = aid
            }

            if let aid = alumnoId {
                alumnoIdEscaneado = aid
                alumnoNombre = nil
                mensaje = ""
                // cargamos datos relevantes
                cargarClasesImpartidas()
                if selectedMode == .revisar { cargarTareasParaProfesor() }
            } else {
                mensaje = "QR inválido o incompleto"
                alumnoIdEscaneado = nil
            }
        case .failure:
            mensaje = "Error al escanear código"
            alumnoIdEscaneado = nil
        }
    }

    // MARK: - Backend calls

    func buscarAlumno(id: Int) {
        guard let url = URL(string: "http://localhost:8000/user/\(id)") else {
            alumnoNombre = nil
            mensaje = "URL de alumno incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let decoded = try? JSONDecoder().decode(UsuarioSimple.self, from: data) {
                    alumnoNombre = decoded.nombre
                } else {
                    alumnoNombre = nil
                    mensaje = "No se encontró el alumno"
                }
            }
        }.resume()
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
                    if let first = clasesImpartidas.first, claseSeleccionada == nil {
                        claseSeleccionada = first
                    }
                }
            }
        }.resume()
    }

    func cargarTareasParaProfesor() {
        guard let url = URL(string: "http://localhost:8000/tareas/profesor/\(userID)") else {
            mensaje = "URL de tareas incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        isLoading = true
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
                guard let data = data else {
                    self.tareas = []
                    mensaje = "No se pudieron cargar tareas"
                    return
                }
                do {
                    // Intento decodificar directamente a [TareaOut]
                    let decoded = try JSONDecoder().decode([TareaOut].self, from: data)
                    self.tareas = decoded
                    if let first = decoded.first, tareaSeleccionadaId == nil {
                        tareaSeleccionadaId = first.id
                    }
                } catch {
                    // Debug: mostrar JSON crudo en consola para ajustar si la respuesta tiene envoltorio
                    if let raw = String(data: data, encoding: .utf8) {
                        print("Error decodificando tareas: \(error). JSON crudo: \(raw)")
                    } else {
                        print("Error decodificando tareas: \(error). No se pudo leer body.")
                    }
                    // Intenta decodificar si el backend devuelve { \"results\": [...] } u otro wrapper
                    if let wrapper = try? JSONDecoder().decode([String: [TareaOut]].self, from: data),
                       let arr = wrapper.values.first {
                        self.tareas = arr
                        if let first = arr.first, tareaSeleccionadaId == nil {
                            tareaSeleccionadaId = first.id
                        }
                    } else {
                        self.tareas = []
                        mensaje = "No se pudieron cargar tareas (ver consola)"
                    }
                }
            }
        }.resume()
    }

    func inscribirAlumno(alumno_id: Int, clase_id: Int) {
        mensaje = ""
        isLoading = true
        guard let url = URL(string: "http://localhost:8000/inscripciones/") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        let body: [String: Any] = ["alumno_id": alumno_id, "clase_id": clase_id]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { mensaje = "Error: \(error.localizedDescription)"; return }
                guard let http = response as? HTTPURLResponse else { mensaje = "Sin respuesta"; return }
                if (200..<300).contains(http.statusCode) {
                    mensaje = "Alumno inscrito con éxito"
                    alumnoIdEscaneado = nil
                    alumnoNombre = nil
                } else {
                    mensaje = "Error (\(http.statusCode))"
                }
            }
        }.resume()
    }

    // Marcar asistencia rápida para un solo alumno, enviando la fecha seleccionada
    func marcarAsistenciaRapida(alumno_id: Int, clase_id: Int, fecha: Date) {
        mensaje = ""
        isLoading = true
        guard let url = URL(string: "http://localhost:8000/asistencias/") else {
            mensaje = "URL de asistencias incorrecta"
            isLoading = false
            return
        }
        let fechaStr = ISO8601DateFormatter().string(from: fecha)
        let dict: [String: Any] = [
            "tema": "Entrada por QR",
            "fecha_clase": fechaStr,
            "id_clase": clase_id,
            "id_alumno": alumno_id
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { mensaje = "Error: \(error.localizedDescription)"; return }
                guard let http = response as? HTTPURLResponse else { mensaje = "Sin respuesta"; return }
                if (200..<300).contains(http.statusCode) {
                    mensaje = "Asistencia marcada con éxito"
                    alumnoIdEscaneado = nil
                    alumnoNombre = nil
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    mensaje = "Error (\(http.statusCode)): \(body)"
                }
            }
        }.resume()
    }

    func marcarTareaRevisada(alumno_id: Int, assignment_id: Int) {
        mensaje = ""
        isLoading = true
        guard let url = URL(string: "http://localhost:8000/tareas/revisadas/") else {
            mensaje = "URL de tareas revisadas incorrecta"
            isLoading = false
            return
        }
        let body: [String: Any] = [
            "alumno_id": alumno_id,
            "assignment_id": assignment_id,
            "revisado_en_clase": true
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { mensaje = "Error: \(error.localizedDescription)"; return }
                guard let http = response as? HTTPURLResponse else { mensaje = "Sin respuesta"; return }
                if (200..<300).contains(http.statusCode) {
                    mensaje = "Tarea marcada como revisada"
                    alumnoIdEscaneado = nil
                    alumnoNombre = nil
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    mensaje = "Error (\(http.statusCode)): \(body)"
                }
            }
        }.resume()
    }
}

// Small reusable button style used above
struct ActionButtonStyle: ButtonStyle {
    var background: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(background.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
