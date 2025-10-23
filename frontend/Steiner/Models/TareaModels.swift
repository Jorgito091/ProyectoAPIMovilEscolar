import Foundation

public struct TareaOut: Identifiable, Codable, Hashable {
    public let id: Int
    public let titulo: String
    public let descripcion: String?
    public let fecha_limite: String?
}

public struct Tarea: Identifiable, Codable {
    public let id: Int
    public let clase_id: Int
    public let titulo: String
    public let descripcion: String?
    public let fecha_creacion: String
    public let fecha_limite: String
}
