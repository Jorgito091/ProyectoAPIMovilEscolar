import SwiftUI
import CodeScanner

struct Alumno: Decodable {
    let id: Int
    let nombre: String
}

struct Clase: Identifiable, Decodable, Hashable {
    let id: Int
    let nombre: String
}

struct UsuarioDetalle: Decodable {
    let id: Int
    let nombre: String
    let rol: String
    let clases_impartidas: [Clase]?
}

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

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 22) {
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

            Text("Inscribir alumno a clase")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 4)

            if alumnoIdEscaneado == nil {
                Button(action: { isShowingScanner = true }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 36, weight: .bold))
                        Text("Escanear QR")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .shadow(radius: 3, y: 2)
                }
                .padding(.horizontal, 16)
                .sheet(isPresented: $isShowingScanner) {
                    CodeScannerView(
                        codeTypes: [.qr],
                        completion: handleScan
                    )
                }
            }

            if let alumnoId = alumnoIdEscaneado {
                VStack(spacing: 14) {
                    Text("ID de alumno: \(alumnoId)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let nombre = alumnoNombre {
                        Text("Nombre: \(nombre)")
                            .font(.title3)
                            .foregroundColor(.blue)
                    } else {
                        ProgressView("Buscando alumno...")
                    }
                    if !clases.isEmpty {
                        Text("Selecciona la clase para inscribir:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Picker("Clase", selection: $claseSeleccionada) {
                            ForEach(clases, id: \.self) { clase in
                                Text(clase.nombre).tag(clase as Clase?)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        Button("Inscribir") {
                            guard let clase = claseSeleccionada, let nombreAlumno = alumnoNombre, !nombreAlumno.isEmpty else {
                                mensaje = "Selecciona una clase y espera el nombre del alumno."
                                return
                            }
                            inscribirAlumno(alumno_id: alumnoId, clase_id: clase.id)
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        ProgressView("Cargando clases...")
                    }
                }
                .padding(.horizontal, 16)
            }

            if isLoading {
                ProgressView("Inscribiendo...")
            }

            if !mensaje.isEmpty {
                Text(mensaje)
                    .font(.headline)
                    .foregroundColor(mensaje.contains("éxito") ? .green : .red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            Spacer()
        }
        .padding()
        .onAppear { cargarClasesImpartidas() }
    }

    // --- Escaneo QR ---
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let scan):
            let contenido = scan.string
            var alumnoId: Int?

            // Intenta decodificar como JSON {alumno_id:123}
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
                buscarAlumno(id: aid)
                mensaje = ""
            } else {
                mensaje = "QR inválido o incompleto"
                alumnoIdEscaneado = nil
            }
        case .failure(_):
            mensaje = "Error al escanear código"
            alumnoIdEscaneado = nil
        }
    }

    // --- Buscar alumno por ID usando /user/<id> ---
    func buscarAlumno(id: Int) {
        guard let url = URL(string: "http://localhost:8000/user/\(id)") else {
            alumnoNombre = nil
            mensaje = "URL de alumno incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Buscar alumno - URL:", url)
        print("Buscar alumno - Token:", accessToken)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let decoded = try? JSONDecoder().decode(Alumno.self, from: data) {
                    alumnoNombre = decoded.nombre
                } else {
                    alumnoNombre = nil
                    mensaje = "No se encontró el alumno"
                }
            }
        }.resume()
    }

    // --- Cargar clases impartidas por el maestro usando /user/<userID> ---
    func cargarClasesImpartidas() {
        guard let url = URL(string: "http://localhost:8000/user/\(userID)") else {
            mensaje = "URL de usuario incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Cargar clases - URL:", url)
        print("Cargar clases - Token:", accessToken)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data,
                   let detalle = try? JSONDecoder().decode(UsuarioDetalle.self, from: data),
                   let clasesImpartidas = detalle.clases_impartidas {
                    self.clases = clasesImpartidas
                    if let first = clasesImpartidas.first {
                        claseSeleccionada = first
                    }
                } else {
                    mensaje = "No se pudieron obtener las clases del usuario"
                }
            }
        }.resume()
    }

    // --- Inscribir ---
    func inscribirAlumno(alumno_id: Int, clase_id: Int) {
        mensaje = ""
        isLoading = true

        // Usa la URL con slash final para evitar redirecciones
        guard let url = URL(string: "http://localhost:8000/inscripciones/") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }

        let body: [String: Any] = [
            "alumno_id": alumno_id,
            "clase_id": clase_id
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

        // PRINTS para depuración
        print("Inscribir - URL:", url)
        print("Inscribir - Token:", accessToken)
        print("Inscribir - Headers:", request.allHTTPHeaderFields ?? [:])
        print("Inscribir - Body:", body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    print("Inscribir - Error:", error.localizedDescription)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    mensaje = "Sin respuesta del servidor"
                    print("Inscribir - No response")
                    return
                }
                print("Inscribir - Status Code:", httpResponse.statusCode)
                if let data = data, let respStr = String(data: data, encoding: .utf8) {
                    print("Inscribir - Backend response:", respStr)
                }
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    mensaje = "Alumno inscrito con éxito"
                    alumnoIdEscaneado = nil
                    alumnoNombre = nil
                } else if httpResponse.statusCode == 401 {
                    mensaje = "No autorizado (401). Revisa el token o permisos."
                } else {
                    mensaje = "Error (\(httpResponse.statusCode)): No se pudo inscribir"
                }
            }
        }.resume()
    }
}
