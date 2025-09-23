import SwiftUI

struct Grupo: Decodable, Identifiable {
    let id: Int
    let nombre: String
}

struct GruposView: View {
    let accessToken: String

    @State private var grupos: [Grupo] = []
    @State private var mensaje: String = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            Button(action: cargarGrupos) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Cargar grupos").frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.horizontal)
            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.purple)
                    .padding()
            }
            List(grupos) { grupo in
                GrupoItemView(grupo: grupo)
            }
        }
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

struct GrupoItemView: View {
    let grupo: Grupo
    var body: some View {
        VStack(alignment: .leading) {
            Text(grupo.nombre)
                .font(.headline)
            Text("ID: \(grupo.id)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
