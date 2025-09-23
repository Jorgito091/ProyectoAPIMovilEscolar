import SwiftUI

struct Tarea: Decodable, Identifiable {
    let id: Int
    let grupo_id: Int
    let titulo: String
    let descripcion: String?
    let fecha_inicio: String?
    let fecha_entrega: String?
    let completada: Bool?
}

struct TareaItemView: View {
    let tarea: Tarea
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(tarea.titulo)
                        .font(.headline)
                    if let desc = tarea.descripcion, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if let fecha = tarea.fecha_entrega {
                        Text("Entrega: \(fecha)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if tarea.completada == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
