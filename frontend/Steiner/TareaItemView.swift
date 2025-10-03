import SwiftUI

struct Tarea: Decodable, Identifiable {
    let id: Int
    let clase_id: Int
    let titulo: String
    let descripcion: String?
    let fecha_creacion: String
    let fecha_limite: String
}

struct TareaItemView: View {
    let tarea: Tarea
    var onTap: (() -> Void)? = nil
    var onUpload: (() -> Void)? = nil
    var isUploading: Bool = false
    
    // Colores
    let cafe = Color(red: 71/255, green: 53/255, blue: 37/255)
    let beige = Color(red: 230/255, green: 220/255, blue: 200/255)

    var body: some View {
        HStack {
            // Contenido principal - clickeable
            Button(action: { onTap?() }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tarea.titulo)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let desc = tarea.descripcion, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("Entrega: \(tarea.fecha_limite)")
                        .font(.caption2)
                        .foregroundColor(cafe)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Botón de menú en la esquina superior derecha
            VStack {
                Menu {
                    Button(action: {
                        if !isUploading {
                            onUpload?()
                        }
                    }) {
                        if isUploading {
                            Label("Subiendo...", systemImage: "arrow.up.circle")
                        } else {
                            Label("Subir entrega", systemImage: "paperclip")
                        }
                    }
                    .disabled(isUploading)
                    
                    Button(action: {
                        onTap?()
                    }) {
                        Label("Ver detalles", systemImage: "info.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(cafe)
                        .font(.title3)
                }
                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(beige.opacity(0.3))
        .cornerRadius(8)
    }
    }

