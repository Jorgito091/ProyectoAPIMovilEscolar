import Foundation

public struct Maestro: Identifiable, Codable {
    public let id: Int
    public let nombre: String
    public let clases_impartidas: [Clase]
}
