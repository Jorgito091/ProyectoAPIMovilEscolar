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
    @State private var showForgotPasswordAlert = false

    // Colores escolares y oscuros
    let cafe = Color(red: 71/255, green: 53/255, blue: 37/255)
    let beige = Color(red: 230/255, green: 220/255, blue: 200/255)
    let cafeOscuro = Color(red: 51/255, green: 37/255, blue: 24/255)
    let fondoOscuro = Color(red: 34/255, green: 27/255, blue: 20/255)

    var body: some View {
        NavigationStack {
            ZStack {
                fondoView
                loginCard
            }
        }
    }

    // Fondo escolar oscuro y café
    var fondoView: some View {
        fondoOscuro
            .ignoresSafeArea()
            .overlay(
                Image("login.jpg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 12)
                    .overlay(cafe.opacity(0.32))
            )
    }

    // Tarjeta principal separada
    var loginCard: some View {
        VStack(spacing: 32) {
            headerView
            fieldsView
            loginButton
            forgotPasswordButton
            errorMessage
            navigationSection
        }
        .padding(.vertical, 38)
        .padding(.horizontal, 22)
        .frame(maxWidth: 380)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(beige.opacity(0.90))
                .shadow(color: cafe.opacity(0.13), radius: 14, x: 0, y: 5)
        )
        .padding()
    }

    var headerView: some View {
        HStack {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 34))
                .foregroundColor(beige)
                .shadow(radius: 3, y: 2)
            Text("Portal Escolar")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(cafeOscuro)
        }
        .padding(.bottom, 10)
    }

    var fieldsView: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(cafe)
                TextField("Matrícula", text: $matricula)
                    .textContentType(.username)
                    .foregroundColor(cafeOscuro)
                    
            }
            .padding(12)
            .background(beige.opacity(0.9))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(cafe.opacity(0.2)))

            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(cafe)
                SecureField("Contraseña", text: $password)
                    .textContentType(.password)
                    .foregroundColor(cafeOscuro)
            }
            .padding(12)
            .background(beige.opacity(0.9))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(cafe.opacity(0.2)))
        }
    }

    var loginButton: some View {
        Button(action: login) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(beige)
                } else {
                    Text("Entrar")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(beige)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cafe)
            .cornerRadius(14)
            .shadow(color: cafeOscuro.opacity(0.22), radius: 8, y: 2)
            .animation(.easeInOut, value: isLoading)
        }
        .disabled(isLoading)
        .padding(.horizontal, 6)
    }

    var forgotPasswordButton: some View {
        Button(action: { showForgotPasswordAlert = true }) {
            Text("Olvidé mi contraseña")
                .font(.footnote)
                .foregroundColor(cafeOscuro)
                .underline()
        }
        .alert("Al rato hago eso", isPresented: $showForgotPasswordAlert) {
            Button("OK", role: .cancel) { }
        }
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

    var navigationSection: some View {
        NavigationLink(
            destination: destinationView,
            isActive: $shouldNavigate,
            label: { EmptyView() }
        )
    }

    @ViewBuilder
    var destinationView: some View {
        if let response = loginResponse {
            if response.rol == "alumno" {
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
