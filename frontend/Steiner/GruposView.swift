import SwiftUI

struct GrupoItemView: View {
    let grupo: Grupo
    let cafe: Color
    let cafeOscuro: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(grupo.nombre)
                .font(.headline)
                .foregroundColor(cafeOscuro)
            Text("ID: \(grupo.id)")
                .font(.subheadline)
                .foregroundColor(cafe)
            if let maestroID = grupo.maestro_id {
                Text("Maestro ID: \(maestroID)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GruposView: View {
    let accessToken: String

    // Colores escolares
    let cafe = Color(red: 71/255, green: 53/255, blue: 37/255)
    let beige = Color(red: 230/255, green: 220/255, blue: 200/255)
    let cafeOscuro = Color(red: 51/255, green: 37/255, blue: 24/255)

    @State private var grupos: [Grupo] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Button(action: cargarGrupos) {
                if isLoading {
                    ProgressView()
                        .tint(beige)
                } else {
                    Text("Cargar grupos")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(beige)
                }
            }
            .padding(.vertical, 10)
            .background(cafe)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: cafeOscuro.opacity(0.08), radius: 4, y: 1)

            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .padding()
            }

            List(grupos) { grupo in
                GrupoItemView(grupo: grupo, cafe: cafe, cafeOscuro: cafeOscuro)
                    .listRowBackground(beige.opacity(0.7))
            }
        }
        .padding(.vertical)
    }

    func cargarGrupos() {
        isLoading = true
        mensaje = ""
        grupos = []
        guard let url = URL(string: "http://localhost:8000/grupos/") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    mensaje = "Error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    mensaje = "Sin datos"
                    return
                }
                do {
                    let gruposDecodificados = try JSONDecoder().decode([Grupo].self, from: data)
                    grupos = gruposDecodificados
                    if grupos.isEmpty {
                        mensaje = "No hay grupos disponibles"
                    }
                } catch {
                    mensaje = "Error al decodificar los grupos"
                }
            }
        }.resume()
    }
}
