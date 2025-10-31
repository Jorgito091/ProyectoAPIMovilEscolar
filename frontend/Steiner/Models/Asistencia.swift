import Foundation

public struct AsistenciaCreate: Codable {
    public let tema: String
    public let fecha_clase: String // ISO8601 string
    public let id_clase: Int
    public let id_alumno: Int
}


public struct AsistenciaOut: Codable, Identifiable {
    public var id: Int { id_alumno * 10000 + id_clase } // ID generado
    public let tema: String
    public let fecha_clase: String
    public let id_clase: Int
    public let id_alumno: Int
    
    enum CodingKeys: String, CodingKey {
        case tema, fecha_clase, id_clase, id_alumno
    }
}
