import SwiftUI

struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String
    let rol: String
    let alumno_id: Int?    
}

struct LoginView: View {
    @State private var matricula: String = ""
    @State private var password: String = ""
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var loginResponse: LoginResponse? = nil
    @State private var shouldNavigate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("login_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 15)
                    .overlay(Color.black.opacity(0.2))

                VStack(spacing: 20) {
                    Text("Steiner")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: 10)

                    TextField("Matrícula", text: $matricula)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    SecureField("Contraseña", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Iniciar sesión")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                    Text(mensaje)
                        .foregroundColor(.red)
                        .padding(.horizontal)

                    NavigationLink(
                        destination: destinationView,
                        isActive: $shouldNavigate,
                        label: { EmptyView() }
                    )
                }
                .frame(maxWidth: 400)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 15)
                )
                .padding()
            }
        }
    }

    // Computed property que devuelve la vista correcta
    @ViewBuilder
    var destinationView: some View {
        if let response = loginResponse {
            if response.rol == "alumno" {
                // Pasa también el alumnoID
                AlView(accessToken: response.access_token, alumnoID: response.alumno_id ?? -1)
            } else if response.rol == "maestro" {
                MView(accessToken: response.access_token)
            } else {
                Text("Rol no reconocido")
            }
        } else {
            EmptyView()
        }
    }

    func login() {
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/user/login") else {
            mensaje = "URL incorrecta"
            isLoading = false
            return
        }

        let loginData = [
            "matricula": matricula,
            "password": password
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: loginData) else {
            mensaje = "Error al preparar datos"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
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
                if httpResponse.statusCode == 200, let data = data {
                    do {
                        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                        loginResponse = decoded
                        shouldNavigate = true
                    } catch {
                        mensaje = "Error al leer respuesta"
                    }
                } else {
                    mensaje = "Credenciales incorrectas o error de servidor (\(httpResponse.statusCode))"
                }
            }
        }.resume()
    }
}
