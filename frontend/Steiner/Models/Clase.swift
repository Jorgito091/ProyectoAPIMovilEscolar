import Foundation

public struct Clase: Codable, Identifiable, Hashable {
    public let id: Int
    public let nombre: String?
    public let matricula: String?
    public let alumnos_inscritos: [UsuarioSimple]?
}
