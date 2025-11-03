import SwiftUI
import CodeScanner
import PDFKit
import UIKit

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

    // Fecha seleccionada para asistencia
    @State private var fechaSeleccionada: Date = Date()

    @State private var selectedMode: Mode = .inscribir


    @State private var showAsisSheet = false
    @State private var showCalTareaSheet = false

    @State private var showCalificarDirecto = false
    @State private var entregaCreada: Entrega? = nil

    @Environment(\.dismiss) var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case inscribir
        case asistencia
        case revisar
        case calificar // Modo para revisar y calificar en clase

        var id: String { self.rawValue }
        var title: String {
            switch self {
            case .inscribir: return "Inscribir"
            case .asistencia: return "Asistencia"
            case .revisar: return "Revisar"
            case .calificar: return "Calificar"
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
                                if clases.isEmpty {
                                    ProgressView("Cargando clases...")
                                } else if tareas.isEmpty {
                                    ProgressView("Cargando tareas...")
                                } else {
                                    Text("Selecciona clase y tarea").font(.subheadline)
                                    Picker("Clase", selection: $claseSeleccionada) {
                                        ForEach(clases, id: \.self) { c in
                                            Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    
                                    Picker("Tarea", selection: $tareaSeleccionadaId) {
                                        ForEach(tareas) { t in
                                            Text(t.titulo).tag(Optional(t.id))
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)

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
                            .padding(.horizontal)
                            
                        case .calificar:
                            VStack(spacing: 10) {
                                if clases.isEmpty {
                                    ProgressView("Cargando clases...")
                                } else if tareas.isEmpty {
                                    ProgressView("Cargando tareas...")
                                } else {
                                    Text("Revisar y calificar en clase").font(.subheadline)
                                    
                                    Picker("Clase", selection: $claseSeleccionada) {
                                        ForEach(clases, id: \.self) { c in
                                            Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    
                                    Picker("Tarea", selection: $tareaSeleccionadaId) {
                                        ForEach(tareas) { t in
                                            Text(t.titulo).tag(Optional(t.id))
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)

                                    Button("Revisar y Calificar") {
                                        guard let tarea = tareaSeleccionada else {
                                            mensaje = "Selecciona una tarea."
                                            return
                                        }
                                        // Crear entrega temporal y abrir para calificar
                                        crearEntregaYCalificar(alumno_id: alumnoId, tarea_id: tarea.id)
                                    }
                                    .buttonStyle(ActionButtonStyle(background: .indigo))
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
                }
                .onChange(of: selectedMode) { newMode in
                    if newMode == .revisar || newMode == .calificar {
                        if let clase = claseSeleccionada {
                            cargarTareasPorClase(claseID: clase.id)
                        }
                    }
                }
                .onChange(of: claseSeleccionada) { nuevaClase in
                    if selectedMode == .revisar || selectedMode == .calificar {
                        if let clase = nuevaClase {
                            cargarTareasPorClase(claseID: clase.id)
                        }
                    }
                }
            }

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
        .sheet(isPresented: $showCalificarDirecto) {
            if let entrega = entregaCreada {
                CalSheet(
                    accessToken: accessToken,
                    entrega: entrega,
                    onCalificar: { calif, comentarios in
                        actualizarEntrega(entregaId: entrega.id, calificacion: calif, comentarios: comentarios)
                    }
                )
            } else {
                VStack(spacing: 20) {
                    ProgressView("Creando entrega...")
                }
                .padding()
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
                cargarClasesImpartidas()
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
                        // Si estamos en modo revisar o calificar, cargamos las tareas
                        if selectedMode == .revisar || selectedMode == .calificar {
                            cargarTareasPorClase(claseID: first.id)
                        }
                    }
                }
            }
        }.resume()
    }

    func cargarTareasPorClase(claseID: Int) {
        isLoading = true
        mensaje = ""
        tareas = []
        guard let url = URL(string: "http://localhost:8000/tareas/clase/\(claseID)") else {
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
                    if let first = tareas.first, tareaSeleccionadaId == nil {
                        tareaSeleccionadaId = first.id
                    }
                    if tareas.isEmpty {
                        mensaje = "No hay tareas para esta clase."
                    }
                } catch {
                    print("Error decodificando tareas: \(error)")
                    mensaje = "Error al decodificar las tareas"
                    tareas = []
                }
            }
        }.resume()
    }
    
    // NUEVO: Crear PDF con el texto "Revisada en clase"
    func crearPDFRevisionEnClase() -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Sistema de Calificaciones",
            kCGPDFContextTitle: "Revisión en Clase"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Tamaño carta
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let bodyFont = UIFont.systemFont(ofSize: 16)
            
            // Título
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titulo = "REVISIÓN EN CLASE"
            let titleSize = titulo.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (pageRect.width - titleSize.width) / 2,
                y: 100,
                width: titleSize.width,
                height: titleSize.height
            )
            titulo.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Contenido
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let fecha = Date()
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "es_MX")
            
            let contenido = """
            
            Esta tarea fue revisada presencialmente en clase.
            
            No se requirió entrega física del documento.
            
            Fecha de revisión: \(formatter.string(from: fecha))
            
            El profesor realizará la calificación correspondiente
            basándose en la revisión realizada en el aula.
            """
            
            let textRect = CGRect(x: 60, y: 200, width: pageRect.width - 120, height: pageRect.height - 300)
            contenido.draw(in: textRect, withAttributes: bodyAttributes)
        }
        
        return data
    }
    
    // NUEVO: Crear una entrega con PDF "Revisada en clase" y abrir para calificar
    // Cambiado: ahora incluye alumno_id en el multipart para que la entrega se registre como del alumno escaneado.
    func crearEntregaYCalificar(alumno_id: Int, tarea_id: Int) {
        mensaje = ""
        isLoading = true
        
        // Crear el PDF
        guard let pdfData = crearPDFRevisionEnClase() else {
            mensaje = "Error al crear el PDF"
            isLoading = false
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"

        // Agregar campo alumno_id para que la entrega se registre para ese alumno
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"alumno_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(alumno_id)\r\n".data(using: .utf8)!)

        // (Opcional) agregar campo que indique que es revisión en clase
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"nota\"\r\n\r\n".data(using: .utf8)!)
        body.append("Revisada en clase\r\n".data(using: .utf8)!)

        // Crear el archivo PDF
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"revision_en_clase.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        guard let url = URL(string: "http://localhost:8000/entregas/tarea/\(tarea_id)") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error al crear entrega: \(error.localizedDescription)"
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    mensaje = "Sin respuesta del servidor"
                    return
                }

                if httpResponse.statusCode == 201 {
                    mensaje = "Entrega creada, cargando para calificar..."
                    // Ahora buscar la entrega recién creada
                    cargarEntregaParaCalificar(alumno_id: alumno_id, tarea_id: tarea_id)
                } else {
                    if let data = data, let serverMsg = String(data: data, encoding: .utf8) {
                        mensaje = "Error (\(httpResponse.statusCode)): \(serverMsg)"
                    } else {
                        mensaje = "Error: Código \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
    
    // Cargar la entrega específica del alumno para calificar
    func cargarEntregaParaCalificar(alumno_id: Int, tarea_id: Int) {
        isLoading = true
        guard let url = URL(string: "http://localhost:8000/entregas/tarea/\(tarea_id)") else {
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
                    let todasEntregas = try JSONDecoder().decode([Entrega].self, from: data)
                    // Buscar la entrega del alumno (la más reciente si hay varias)
                    if let entrega = todasEntregas.filter({ $0.alumno.id == alumno_id }).last {
                        entregaCreada = entrega
                        showCalificarDirecto = true
                    } else {
                        mensaje = "No se encontró entrega del alumno"
                    }
                } catch {
                    mensaje = "Error al decodificar entregas: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // Actualizar calificación de una entrega
    func actualizarEntrega(entregaId: Int, calificacion: Float, comentarios: String) {
        guard let url = URL(string: "http://localhost:8000/entregas/\(entregaId)") else {
            mensaje = "URL incorrecta"
            return
        }
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
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    mensaje = "Calificación guardada con éxito"
                    showCalificarDirecto = false
                    alumnoIdEscaneado = nil
                    alumnoNombre = nil
                    entregaCreada = nil
                } else {
                    mensaje = "Error al guardar calificación"
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
}

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
