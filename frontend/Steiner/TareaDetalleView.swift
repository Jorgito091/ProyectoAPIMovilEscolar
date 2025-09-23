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
            if let fechaInicio = tarea.fecha_inicio {
                Text("Inicio: \(fechaInicio)")
            }
            if let fechaEntrega = tarea.fecha_entrega {
                Text("Entrega: \(fechaEntrega)")
            }
            if let completada = tarea.completada {
                Text(completada ? "Completada" : "Pendiente")
                    .foregroundColor(completada ? .green : .orange)
            }
            Spacer()
        }
        .padding()
    }
}
