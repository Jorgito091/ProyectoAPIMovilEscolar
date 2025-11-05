import SwiftUI

struct SignQRView: View {
    @StateObject private var vm: SignQRViewModel
    @State private var isShowingScanner = false
    @State private var selectedMode: Mode = .inscribir
    @State private var claseSeleccionada: Clase? = nil
    @State private var fechaSeleccionada: Date = Date()
    @State private var tareaSeleccionadaId: Int? = nil

    enum Mode: String, CaseIterable, Identifiable {
        case inscribir, asistencia, calificar
        var id: String { rawValue }
        var title: String {
            switch self {
            case .inscribir: return "Inscribir"
            case .asistencia: return "Asistencia"
            case .calificar: return "Calificar"
            }
        }
    }

    init(accessToken: String, userID: Int) {
        _vm = StateObject(wrappedValue: SignQRViewModel(token: accessToken, userID: userID))
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack { Spacer()
                Button(action: { vm.alumnoIdEscaneado = nil; vm.alumnoNombre = nil }) {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.secondary).padding(8)
                }
            }.padding(.trailing, 3).padding(.top, 3)

            Text("Operaciones por QR").font(.title2).fontWeight(.bold)

            if vm.alumnoIdEscaneado == nil {
                Button {
                    isShowingScanner = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder").font(.system(size: 34, weight: .bold))
                        Text("Escanear QR").font(.headline)
                    }.padding().frame(maxWidth: .infinity).background(Color.green.opacity(0.85)).foregroundColor(.white).cornerRadius(12)
                }
                .padding(.horizontal)
                .sheet(isPresented: $isShowingScanner) {
                    QRScannerView { result in
                        isShowingScanner = false
                        switch result {
                        case .success(let scan):
                            handleScanString(scan.string)
                        case .failure:
                            vm.mensaje = "Error al escanear"
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Alumno ID: \(vm.alumnoIdEscaneado ?? 0)").font(.headline)
                            Text(vm.alumnoNombre ?? "Buscando...").font(.subheadline).foregroundColor(.blue)
                        }
                        Spacer()
                        Button { vm.alumnoIdEscaneado = nil; vm.alumnoNombre = nil } label: {
                            Text("Cancelar").foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)

                    Picker("Acción", selection: $selectedMode) {
                        ForEach(Mode.allCases) { m in Text(m.title).tag(m) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    Group {
                        switch selectedMode {
                        case .inscribir:
                            inscribirSection
                        case .asistencia:
                            asistenciaSection
                        case .calificar:
                            calificarSection
                        }
                    }
                }
                .onAppear {
                    if let aid = vm.alumnoIdEscaneado {
                        vm.buscarAlumno(id: aid)
                        vm.cargarClasesImpartidas()
                    }
                }
                .onChange(of: selectedMode) { new in
                    if new == .calificar {
                        if let clase = claseSeleccionada {
                            vm.cargarTareasPorClase(claseID: clase.id)
                        } else if let first = vm.clases.first {
                            claseSeleccionada = first
                            vm.cargarTareasPorClase(claseID: first.id)
                        }
                    }
                }
                .onChange(of: claseSeleccionada) { newClase in
                    if selectedMode == .calificar, let c = newClase {
                        vm.cargarTareasPorClase(claseID: c.id)
                    }
                }
            }

            if vm.isLoading { ProgressView().padding() }
            if !vm.mensaje.isEmpty { Text(vm.mensaje).foregroundColor(.red).padding(.horizontal) }
            Spacer()
        }
        .padding(.top)
        .sheet(isPresented: $vm.showAsisSheet) {
            AsisView(accessToken: vm.token ?? "", userID: vm.userID)
        }
        .sheet(isPresented: $vm.showCalTareaSheet) {
            if let tarea = vm.tareas.first(where: { $0.id == tareaSeleccionadaId }) {
                CalTareaView(accessToken: vm.token ?? "", tareaID: tarea.id)
            } else {
                Text("No se seleccionó tarea")
            }
        }
        .sheet(isPresented: $vm.showCalificarDirecto) {
            if let entrega = vm.entregaCreada {
                CalSheet(accessToken: vm.token ?? "", entrega: entrega) { calif, comentarios in
                    vm.actualizarEntrega(entregaId: entrega.id, calificacion: calif, comentarios: comentarios)
                }
            } else {
                ProgressView("Cargando entrega...")
            }
        }
    }

    // MARK: - Sections & helpers

    private var clasesList: [Clase] { vm.clases }

    private var inscribirSection: some View {
        VStack(spacing: 10) {
            if clasesList.isEmpty { ProgressView("Cargando clases...") }
            else {
                Text("Selecciona clase para inscribir").font(.subheadline)
                Picker("Clase", selection: Binding(get: { claseSeleccionada }, set: { claseSeleccionada = $0 })) {
                    ForEach(clasesList, id: \.self) { c in Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?) }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)

                Button("Inscribir") {
                    guard let clase = claseSeleccionada, let aid = vm.alumnoIdEscaneado else { vm.mensaje = "Selecciona clase"; return }
                    vm.inscribirAlumno(alumno_id: aid, clase_id: clase.id)
                }
                .buttonStyle(ActionButtonStyle(background: .blue))
            }
        }.padding(.horizontal)
    }

    private var asistenciaSection: some View {
        VStack(spacing: 10) {
            if clasesList.isEmpty { ProgressView("Cargando clases...") }
            else {
                Text("Selecciona clase y fecha").font(.subheadline)
                Picker("Clase", selection: Binding(get: { claseSeleccionada }, set: { claseSeleccionada = $0 })) {
                    ForEach(clasesList, id: \.self) { c in Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?) }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 120)

                DatePicker("Fecha", selection: $fechaSeleccionada, displayedComponents: [.date]).datePickerStyle(.compact).padding(.horizontal)

                HStack(spacing: 10) {
                    Button("Marcar asistencia rápida") {
                        guard let clase = claseSeleccionada, let aid = vm.alumnoIdEscaneado else { vm.mensaje = "Selecciona clase"; return }
                        vm.marcarAsistenciaRapida(alumno_id: aid, clase_id: clase.id, fecha: fechaSeleccionada)
                    }
                    .buttonStyle(ActionButtonStyle(background: .purple))

                    Button("Abrir Asistencias") { vm.showAsisSheet = true }
                        .buttonStyle(ActionButtonStyle(background: .orange))
                }
            }
        }.padding(.horizontal)
    }

    private var calificarSection: some View {
        VStack(spacing: 10) {
            if clasesList.isEmpty { ProgressView("Cargando clases...") }
            else if vm.tareas.isEmpty {
                VStack {
                    Text("Selecciona clase para cargar tareas").font(.subheadline)
                    Picker("Clase", selection: Binding(get: { claseSeleccionada }, set: { claseSeleccionada = $0 })) {
                        ForEach(clasesList, id: \.self) { c in Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?) }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                    Button("Cargar tareas") {
                        if let c = claseSeleccionada { vm.cargarTareasPorClase(claseID: c.id) }
                    }
                    .buttonStyle(ActionButtonStyle(background: .indigo))
                }
            } else {
                Text("Selecciona clase y tarea para crear entrega").font(.subheadline)
                Picker("Clase", selection: Binding(get: { claseSeleccionada }, set: { claseSeleccionada = $0 })) {
                    ForEach(clasesList, id: \.self) { c in Text(c.nombre ?? "Clase \(c.id)").tag(c as Clase?) }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 100)

                Picker("Tarea", selection: $tareaSeleccionadaId) {
                    ForEach(vm.tareas) { t in Text(t.titulo).tag(Optional(t.id)) }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 100)

                Button("Revisar y Calificar (crear entrega)") {
                    guard let tareaId = tareaSeleccionadaId, let aid = vm.alumnoIdEscaneado else { vm.mensaje = "Selecciona tarea y alumno"; return }
                    vm.crearEntregaYCalificar(alumno_id: aid, tarea_id: tareaId)
                }
                .buttonStyle(ActionButtonStyle(background: .indigo))
            }
        }.padding(.horizontal)
    }

    // Handle scanned string (JSON or plain int)
    private func handleScanString(_ contenido: String) {
        var alumnoId: Int?
        if let data = contenido.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let aid = json["alumno_id"] as? Int {
            alumnoId = aid
        } else if let aid = Int(contenido) {
            alumnoId = aid
        }

        if let aid = alumnoId {
            vm.alumnoIdEscaneado = aid
            vm.alumnoNombre = nil
            vm.mensaje = ""
            vm.cargarClasesImpartidas()
        } else {
            vm.mensaje = "QR inválido o incompleto"
            vm.alumnoIdEscaneado = nil
        }
    }
}
