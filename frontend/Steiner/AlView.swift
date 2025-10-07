import SwiftUI

struct AlView: View {
    let accessToken: String
    let userID: Int

    // Paleta de colores
    let tintoPrincipal = Color(red: 117/255, green: 22/255, blue: 46/255)
    let tintoClaro = Color(red: 170/255, green: 36/255, blue: 63/255)
    let blanco = Color.white
    let grisClaro = Color(red: 230/255, green: 220/255, blue: 220/255)

    @State private var grupos: [Grupo] = []
    @State private var selectedGrupoID: Int? = nil
    @State private var mensajeGrupo: String = ""
    @State private var showQR = false

    var body: some View {
        ZStack {
            tintoPrincipal.ignoresSafeArea()
            VStack(spacing: 20) {
                // Header con saludo y botón QR
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(tintoClaro)
                    Text("¡Bienvenido, Alumno!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(blanco)
                    Spacer()
                    Button(action: { showQR = true }) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(tintoClaro)
                            .padding(10)
                            .background(blanco.opacity(0.22))
                            .clipShape(Circle())
                            .shadow(color: tintoPrincipal.opacity(0.15), radius: 3, y: 2)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 8)
                .padding(.horizontal, 12)

                // Picker de grupo
                if grupos.isEmpty {
                    ProgressView("Cargando grupos...")
                        .onAppear { cargarGrupos() }
                } else {
                    Picker("Selecciona un grupo", selection: $selectedGrupoID) {
                        ForEach(grupos) { grupo in
                            Text(grupo.nombre).tag(grupo.id as Int?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .background(grisClaro.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.top, 8)
                }

                if !mensajeGrupo.isEmpty {
                    Text(mensajeGrupo)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Aquí se llama a VerTareasView con los parámetros correctos
                VStack(spacing: 28) {
                    Divider().background(tintoClaro.opacity(0.25))
                    if let grupoID = selectedGrupoID {
                        VerTareasView(accessToken: accessToken, alumnoID: userID, grupoID: grupoID)
                    } else {
                        Text("Selecciona un grupo para ver las tareas.")
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        // Hoja modal para QR
        .sheet(isPresented: $showQR) {
            QRView(alumnoID: userID)
        }
    }

    func cargarGrupos() {
        guard let url = URL(string: "http://localhost:8000/user/\(userID)/clases") else {
            mensajeGrupo = "URL de grupos incorrecta"
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                if let data = data {
                    if let decoded = try? JSONDecoder().decode([Grupo].self, from: data) {
                        grupos = decoded
                        if let primero = decoded.first {
                            selectedGrupoID = primero.id
                        }
                    } else {
                        mensajeGrupo = "Error al decodificar los grupos"
                    }
                } else {
                    mensajeGrupo = "No se pudieron cargar los grupos"
                }
            }
        }.resume()
    }
}
