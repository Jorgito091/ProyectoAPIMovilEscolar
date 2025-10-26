import SwiftUI

struct MView: View {
    let accessToken: String
    let userID: Int

    enum Seccion: String, CaseIterable, Identifiable {
        case ver = "Ver"
        case qr = "QR"
        case asistencias = "Asistencias"

        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .ver: return "list.bullet.rectangle.portrait"
            case .qr: return "qrcode.viewfinder"
            case .asistencias: return "person.3.fill"
            }
        }
        var color: Color {
            switch self {
            case .ver: return .green
            case .qr: return .mint
            case .asistencias: return .purple
            }
        }
    }

    static let tabSections: [Seccion] = [.ver, .qr, .asistencias]
    @State private var selected: Seccion = .ver
    @State private var mostrarCrearTarea = false

    var body: some View {
        NavigationStack {
            ZStack {
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

     
                    Group {
                        switch selected {
                        case .ver:
                            VerTareasMaestroView(accessToken: accessToken, userID: userID)
                        case .qr:
                            SignQRView(accessToken: accessToken, userID: userID)
                        case .asistencias:
                            AsisView(accessToken: accessToken, userID: userID)
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

                // FAB: botón de crear tarea
                if selected == .ver {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                mostrarCrearTarea = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 3.5)
                            }
                            .padding(.bottom, 80)
                            .padding(.trailing, 24)
                            .accessibilityLabel("Crear tarea")
                        }
                    }
                    .transition(.scale)
                }
            }
            // Sheet para crear tarea
            .sheet(isPresented: $mostrarCrearTarea) {
                CrearTareaView(accessToken: accessToken, userID: userID)
            }
        }
    }
}
