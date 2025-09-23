import SwiftUI

struct MView: View {
    let accessToken: String

    enum Seccion {
        case crear, ver, editar, eliminar, grupos
    }
    @State private var seccion: Seccion? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("¡Bienvenido!")
                .font(.title)
                .padding(.top)

            HStack(spacing: 8) {
                Button(action: { seccion = .crear }) {
                    Text("Crear tarea")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .crear ? Color.blue.opacity(0.9) : Color.blue.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: { seccion = .ver }) {
                    Text("Ver tareas")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .ver ? Color.green.opacity(0.9) : Color.green.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: { seccion = .editar }) {
                    Text("Editar tarea")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .editar ? Color.orange.opacity(0.9) : Color.orange.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: { seccion = .eliminar }) {
                    Text("Eliminar tarea")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .eliminar ? Color.red.opacity(0.9) : Color.red.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: { seccion = .grupos }) {
                    Text("Ver grupos")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(seccion == .grupos ? Color.purple.opacity(0.9) : Color.purple.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            Divider()

            switch seccion {
            case .crear:
                CrearTareaView(accessToken: accessToken)
            case .ver:
                VerTareasView(accessToken: accessToken)
            case .editar:
                EditarTareaView(accessToken: accessToken)
            case .eliminar:
                EliminarTareaView(accessToken: accessToken)
            case .grupos:
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
