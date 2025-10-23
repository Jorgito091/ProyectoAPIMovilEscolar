import Foundation

public struct Grupo: Codable, Identifiable, Hashable {
    public let id: Int
    public let nombre: String
    public let maestro_id: Int?
}
