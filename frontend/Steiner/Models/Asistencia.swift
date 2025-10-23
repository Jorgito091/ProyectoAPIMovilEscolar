import Foundation

public struct AsistenciaCreate: Codable {
    public let tema: String
    public let fecha_clase: String // ISO8601 string
    public let id_clase: Int
    public let id_alumno: Int
}

public struct AsistenciaOut: Codable, Identifiable {
    public let id: Int
    public let tema: String
    public let fecha_clase: String
    public let id_clase: Int
    public let id_alumno: Int
}
