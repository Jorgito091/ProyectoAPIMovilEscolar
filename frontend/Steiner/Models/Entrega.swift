import Foundation

public struct Entrega: Identifiable, Codable, Hashable {
    public let id: Int
    public let storage_path: String
    public let fecha_entrega: String
    public let calificacion: Float?
    public let comentarios: String?
    public let alumno: UsuarioSimple
    public let tarea: TareaOut
}
