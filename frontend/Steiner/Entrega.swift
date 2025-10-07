import Foundation

struct Entrega: Identifiable, Decodable {
    let id: Int
    let storage_path: String
    let fecha_entrega: String
    let calificacion: Float?
    let comentarios: String?
    let alumno: UsuarioSimple
    let tarea: TareaOut
}

struct UsuarioSimple: Decodable {
    let id: Int
    let nombre: String
}

struct TareaOut: Identifiable, Decodable , Hashable  {
    let id: Int
    let titulo: String
}
