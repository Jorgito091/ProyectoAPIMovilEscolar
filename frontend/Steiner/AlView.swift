import SwiftUI

struct AlView: View {
    let accessToken: String
    let alumnoID: Int

    enum Seccion {
        case verTareas, verGrupos
    }
    @State private var seccion: Seccion? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("¡Bienvenido Alumno!")
                .font(.title)
                .padding(.top)

            HStack(spacing: 8) {
                Button(action: { seccion = .verTareas }) {
                    Text("Ver tareas")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .verTareas ? Color.green.opacity(0.9) : Color.green.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: { seccion = .verGrupos }) {
                    Text("Ver grupos")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .verGrupos ? Color.purple.opacity(0.9) : Color.purple.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            Divider()

            switch seccion {
            case .verTareas:
                VerTareasView(accessToken: accessToken, alumnoID: alumnoID)
            case .verGrupos:
                GruposView(accessToken: accessToken)
            default:
                Text("Selecciona una opción para continuar")
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()
        }
        .padding()
    }
}
