import SwiftUI

struct LoginResponse: Decodable {
    let access_token: String
    let token_type: String
    let rol: String
    let id: Int
}

struct LoginView: View {
    @State private var matricula: String = ""
    @State private var password: String = ""
    @State private var mensaje: String = ""
    @State private var isLoading = false
    @State private var loginResponse: LoginResponse? = nil
    @State private var shouldNavigate = false
    @State private var showForgotPasswordAlert = false

    // Paleta tinto
    let tintoPrincipal = Color(red: 117/255, green: 22/255, blue: 46/255)
    let tintoClaro = Color(red: 170/255, green: 36/255, blue: 63/255)
    let blanco = Color.white
    let grisClaro = Color(red: 230/255, green: 220/255, blue: 220/255)

    var body: some View {
        NavigationStack {
            ZStack {
                fondoView
                loginCard
            }
            .navigationDestination(isPresented: $shouldNavigate) {
                if let response = loginResponse {
                    if response.rol == "alumno" {
                        AlView(accessToken: response.access_token, userID: response.id)
                    } else if response.rol == "maestro" {
                        MView(accessToken: response.access_token, userID: response.id)
                    } else {
                        Text("Rol no reconocido")
                    }
                }
            }
        }
    }

    var fondoView: some View {
        LinearGradient(gradient: Gradient(colors: [tintoPrincipal, tintoClaro]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .overlay(
                ZStack {
                    Circle()
                        .fill(tintoClaro.opacity(0.18))
                        .frame(width: 340, height: 340)
                        .offset(x: -120, y: -220)
                    Circle()
                        .fill(tintoPrincipal.opacity(0.10))
                        .frame(width: 210, height: 210)
                        .offset(x: 140, y: 250)
                }
            )
    }

    var loginCard: some View {
        VStack(spacing: 36) {
            headerView
            fieldsView
            loginButton
            forgotPasswordButton
            errorMessage
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 28)
        .frame(maxWidth: 390)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(blanco)
                .shadow(color: tintoPrincipal.opacity(0.09), radius: 22, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(tintoClaro.opacity(0.22), lineWidth: 1.4)
        )
        .padding(.horizontal)
        .padding(.vertical, 14)
    }

    var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 44))
                .foregroundColor(tintoPrincipal)
                .shadow(radius: 3, y: 2)
                .padding(.bottom, 2)
            Text("Bienvenido")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(tintoPrincipal)
            Text("Portal Escolar")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.bottom, 12)
    }

    var fieldsView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(tintoPrincipal)
                TextField("Matrícula", text: $matricula)
                    .textContentType(.username)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
            }
            .padding(14)
            .background(grisClaro.opacity(0.55))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tintoPrincipal.opacity(0.22)))

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(tintoPrincipal)
                SecureField("Contraseña", text: $password)
                    .textContentType(.password)
                    .foregroundColor(.primary)
            }
            .padding(14)
            .background(grisClaro.opacity(0.55))
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(tintoPrincipal.opacity(0.22)))
        }
    }

    var loginButton: some View {
        Button(action: login) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.white)
                } else {
                    Text("Entrar")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2, y: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(LinearGradient(gradient: Gradient(colors: [tintoPrincipal, tintoClaro]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(18)
            .shadow(color: tintoPrincipal.opacity(0.23), radius: 10, y: 4)
            .animation(.easeInOut, value: isLoading)
        }
        .disabled(isLoading)
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    var forgotPasswordButton: some View {
        Button(action: { showForgotPasswordAlert = true }) {
            Text("¿Olvidaste tu contraseña?")
                .font(.footnote)
                .foregroundColor(tintoPrincipal)
                .underline()
        }
        .alert("¡Pronto estará disponible la recuperación de contraseña!", isPresented: $showForgotPasswordAlert) {
            Button("OK", role: .cancel) { }
        }
        .padding(.top, -8)
    }

    var errorMessage: some View {
        Group {
            if !mensaje.isEmpty {
                Text(mensaje)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
    }

    func login() {
        isLoading = true
        mensaje = ""
        guard let url = URL(string: "http://localhost:8000/auth/login") else {
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
