import SwiftUI

struct CalSheet: View {
    let accessToken: String
    let entrega: Entrega
    var onCalificar: (Float, String) -> Void

    @State private var calificacion: Float = 10.0
    @State private var comentarios: String = ""
    @Environment(\.dismiss) private var dismiss

    // URL base para el bucket "entregas" en tu proyecto Supabase
    let supabaseBaseURL = "https://bldhkjnpylapzlvvjmfp.supabase.co/storage/v1/object/public/entregas/"
    var archivoURL: URL? {
        // Si el storage_path ya es una URL pública completa, úsala directa
        if entrega.storage_path.starts(with: "http") {
            return URL(string: entrega.storage_path)
        } else {
            // Si es solo el path, arma la URL pública
            return URL(string: "\(supabaseBaseURL)\(entrega.storage_path)")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Calificar Entrega de \(entrega.alumno.nombre)")
                .font(.headline)
            if let url = archivoURL {
                Link("Ver archivo entregado", destination: url)
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
            } else {
                Text("No se pudo construir la URL del archivo.")
                    .foregroundColor(.red)
            }
            HStack {
                Text("Calificación:")
                Slider(value: $calificacion, in: 0...10, step: 0.1)
                    .frame(width: 120)
                Text(String(format: "%.1f", calificacion))
            }
            .padding(.vertical, 8)
            TextField("Comentarios", text: $comentarios)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)
            Button("Guardar calificación") {
                onCalificar(calificacion, comentarios)
                dismiss()
            }
            .padding()
            .background(Color.green.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Cerrar") {
                dismiss()
            }
            .padding(.top, 10)
            .foregroundColor(.red)
        }
        .padding()
        .onAppear {
            // Si ya existe calificación/comentario previa, precarga
            if let calif = entrega.calificacion {
                calificacion = calif
            }
            if let coment = entrega.comentarios {
                comentarios = coment
            }
        }
    }
}
