import SwiftUI



struct AsisView: View {
    let accessToken: String
    let userID: Int

    @State private var clases: [Clase] = []
    @State private var alumnosPorClase: [Int: [UsuarioSimple]] = [:]
    @State private var asistenciaEstado: [Int: [Int: Bool]] = [:]
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

            Picker("Clase", selection: $selectedClaseId) {
                Text("Selecciona").tag(Optional<Int>(nil))
                ForEach(clases) { c in
                    Text(c.nombre ?? "Clase \(c.id)").tag(Optional(c.id))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedClaseId) { newId in
                if let id = newId {
                    cargarAlumnos(claseId: id)
                }
            }

            DatePicker("Fecha", selection: $selectedFecha, displayedComponents: .date)
                .padding(.horizontal)
                .onChange(of: selectedFecha) { _ in
                    print("📅 Fecha cambió a: \(dateOnlyString(from: selectedFecha))")
                    if let claseId = selectedClaseId {
                        cargarAsistenciasExistentes(claseId: claseId, fecha: selectedFecha)
                    }
                }

            TextField("Tema de la clase (opcional)", text: $tema)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            if isLoading {
                ProgressView("Cargando...")
            } else if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(mensaje.contains("éxito") || mensaje.contains("pudo") || mensaje.contains("cargaron") ? .green : .red)
                    .padding(.horizontal)
                    .font(.caption)
            }

            if let claseId = selectedClaseId, let alumnos = alumnosPorClase[claseId] {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(alumnos, id: \.id) { alumno in
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
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
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
                    .background(selectedClaseId == nil ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .disabled(selectedClaseId == nil)

            Spacer()
        }
        .onAppear(perform: cargarClases)
    }

    func iso8601String(from date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: date)
    }
    
    func dateOnlyString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
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
                    if self.clases.isEmpty {
                        self.mensaje = "No hay clases."
                    } else {
                        if self.selectedClaseId == nil {
                            self.selectedClaseId = self.clases.first?.id
                        }
                    }
                } catch {
                    mensaje = "Error al decodificar clases: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    func cargarAlumnos(claseId: Int) {
        print("🔄 Cargando alumnos para clase \(claseId)")
        guard let url = URL(string: "http://localhost:8000/clases/\(claseId)") else {
            mensaje = "URL incorrecta para alumnos"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                if let err = err {
                    mensaje = "Error cargando alumnos: \(err.localizedDescription)"
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos de alumnos"
                    return
                }

                do {
                    let clase = try JSONDecoder().decode(Clase.self, from: data)
                    let alumnos = clase.alumnos_inscritos ?? []
                    self.alumnosPorClase[claseId] = alumnos
                    print("✅ Cargados \(alumnos.count) alumnos")

                    // Inicializar todos como ausentes
                    var estado: [Int: Bool] = [:]
                    for a in alumnos {
                        estado[a.id] = false
                    }
                    self.asistenciaEstado[claseId] = estado
                    
                    // Cargar asistencias existentes
                    self.cargarAsistenciasExistentes(claseId: claseId, fecha: self.selectedFecha)
                } catch {
                    mensaje = "Error al decodificar alumnos: \(error.localizedDescription)"
                    print("❌ Decoding error:", error)
                }
            }
        }.resume()
    }

    func cargarAsistenciasExistentes(claseId: Int, fecha: Date) {
        let fechaBuscada = dateOnlyString(from: fecha)
        print("🔍 Buscando asistencias para clase \(claseId) fecha \(fechaBuscada)")
        
        guard let url = URL(string: "http://localhost:8000/asistencias/clase/\(claseId)") else {
            print("❌ URL inválida")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, err in
            DispatchQueue.main.async {
                if let err = err {
                    print("❌ Error cargando asistencias: \(err.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("❌ Sin datos")
                    return
                }
                
                do {
                    let asistencias = try JSONDecoder().decode([AsistenciaOut].self, from: data)
                    print("📚 Total asistencias de la clase: \(asistencias.count)")
                    
                    // Filtrar asistencias por la fecha seleccionada
                    let asistenciasDia = asistencias.filter { asistencia in
                        asistencia.fecha_clase.starts(with: fechaBuscada)
                    }
                    
                    print("📅 Asistencias para \(fechaBuscada): \(asistenciasDia.count)")
                    
                    // Actualizar tema
                    if let primeraAsistencia = asistenciasDia.first {
                        self.tema = primeraAsistencia.tema
                        print("📝 Tema cargado: \(primeraAsistencia.tema)")
                    } else {
                        self.tema = ""
                    }
                    
                    // Actualizar estado
                    var estado = self.asistenciaEstado[claseId] ?? [:]
                    
                    // Reset a todos como ausentes
                    if let alumnos = alumnosPorClase[claseId] {
                        for alumno in alumnos {
                            estado[alumno.id] = false
                        }
                    }
                    
                    // Marcar presentes
                    for asistencia in asistenciasDia {
                        estado[asistencia.id_alumno] = true
                        print("✅ Alumno \(asistencia.id_alumno) marcado presente")
                    }
                    
                    self.asistenciaEstado[claseId] = estado
                    
                    if !asistenciasDia.isEmpty {
                        self.mensaje = "✅ Se cargaron \(asistenciasDia.count) asistencias"
                    } else {
                        self.mensaje = "Sin registros para esta fecha"
                    }
                    
                } catch {
                    print("❌ Error decodificando: \(error)")
                }
            }
        }.resume()
    }

    func marcarPresente(claseId: Int, alumnoId: Int, presente: Bool) {
        var estado = asistenciaEstado[claseId] ?? [:]
        estado[alumnoId] = presente
        asistenciaEstado[claseId] = estado
        print("👤 Alumno \(alumnoId): \(presente ? "Presente" : "Ausente")")
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
        let temaFinal = tema.isEmpty ? "Clase \(dateOnlyString(from: selectedFecha))" : tema

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
                errores.append("URL inválida")
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
                    } else if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                        errores.append("Alumno \(alumno.nombre): status \(http.statusCode)")
                    }
                    group.leave()
                }
            }.resume()
        }

        group.notify(queue: .main) {
            isLoading = false
            if errores.isEmpty {
                mensaje = "✅ Asistencias guardadas con éxito"
            } else {
                mensaje = "⚠️ Algunas asistencias fallaron"
            }
        }
    }
}
