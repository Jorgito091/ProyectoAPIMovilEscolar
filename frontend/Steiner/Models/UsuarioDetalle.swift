import Foundation

public struct UsuarioDetalle: Codable {
    public let id: Int
    public let nombre: String
    public let rol: String?
    public let clases_impartidas: [Clase]?
    // Añade otros campos devueltos por /user/{id} si los necesitas
}
