import SwiftUI

struct MView: View {
    let accessToken: String
    let userID: Int

    enum Seccion: String, CaseIterable, Identifiable {
        case crear = "Crear"
        case ver = "Ver"
        case editar = "Editar"
        case eliminar = "Eliminar"
        case qr = "QR"
        case asistencias = "Asistencias"

        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .crear: return "plus.circle.fill"
            case .ver: return "list.bullet.rectangle.portrait"
            case .editar: return "pencil.circle.fill"
            case .eliminar: return "trash.circle.fill"
            case .qr: return "qrcode.viewfinder"
            case .asistencias: return "person.3.fill"
            }
        }
        var color: Color {
            switch self {
            case .crear: return .blue
            case .ver: return .green
            case .editar: return .orange
            case .eliminar: return .red
            case .qr: return .mint
            case .asistencias: return .purple
            }
        }
    }

    static let tabSections: [Seccion] = [.crear, .ver, .editar, .eliminar, .qr, .asistencias]
    @State private var selected: Seccion = .ver
    @State private var selectedClase: Clase? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: selected.icon)
                        .foregroundColor(selected.color)
                        .font(.system(size: 32))
                        .padding(.trailing, 6)
                    Text("¡Bienvenido, Maestro!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(selected.color)
                }
                .padding(.top, 24)
                .padding(.bottom, 12)

                Divider()

                // Sección dinámica
                Group {
                    switch selected {
                    case .crear:
                        CrearTareaView(accessToken: accessToken, userID: userID)
                    case .ver:
                        VerTareasMaestroView(accessToken: accessToken, userID: userID)
                    case .editar:
                        EditarTareaView(accessToken: accessToken, userID: userID)
                    case .eliminar:
                        EliminarTareaView(accessToken: accessToken, userID: userID)
                    case .qr:
                        SignQRView(accessToken: accessToken, userID: userID)
                    case .asistencias:
                        AsisView() // <-- Aquí se llama la vista de asistencias sin parámetros ni lógica
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(18)
                .padding(.horizontal)
                .padding(.top, 12)

                // Tab bar
                Divider()
                HStack {
                    ForEach(MView.tabSections, id: \.id) { section in
                        Button(action: { selected = section }) {
                            VStack(spacing: 2) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 22, weight: .bold))
                                Text(section.rawValue)
                                    .font(.footnote)
                                    .fontWeight(selected == section ? .bold : .regular)
                            }
                            .foregroundColor(selected == section ? section.color : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(.thinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}
