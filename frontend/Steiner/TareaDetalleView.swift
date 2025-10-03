import SwiftUI

struct TareaDetalleView: View, Identifiable {
    let id = UUID()
    let tarea: Tarea
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            Text(tarea.titulo)
                .font(.largeTitle)
            if let descripcion = tarea.descripcion {
                Text("Descripción: \(descripcion)")
            }
            Text("Creada: \(tarea.fecha_creacion)")
            Text("Entrega: \(tarea.fecha_limite)")
            Spacer()
        }
        .padding()
    }
}
