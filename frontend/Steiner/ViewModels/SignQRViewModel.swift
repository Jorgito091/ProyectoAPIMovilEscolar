import Foundation
import SwiftUI

@MainActor
final class SignQRViewModel: ObservableObject {
    // Dependencies
    private let api: APIService
    let token: String?     // expuesto para que la View pueda pasar al sheet
    let userID: Int

    // Published state
    @Published var alumnoIdEscaneado: Int? = nil
    @Published var alumnoNombre: String? = nil
    @Published var clases: [Clase] = []
    @Published var tareas: [TareaOut] = []
    @Published var mensaje: String = ""
    @Published var isLoading: Bool = false
    @Published var showAsisSheet: Bool = false
    @Published var showCalTareaSheet: Bool = false
    @Published var showCalificarDirecto: Bool = false
    @Published var entregaCreada: Entrega? = nil

    init(baseURL: URL = URL(string: "http://localhost:8000")!, token: String?, userID: Int) {
        self.api = APIService(baseURL: baseURL, token: token)
        self.token = token
        self.userID = userID
    }

    // MARK: - Network methods

    func buscarAlumno(id: Int) {
        isLoading = true
        api.fetch("/user/\(id)", as: UsuarioSimple.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let u):
                    self?.alumnoNombre = u.nombre
                case .failure:
                    self?.alumnoNombre = nil
                    self?.mensaje = "No se encontró el alumno"
                }
            }
        }
    }

    func cargarClasesImpartidas() {
        isLoading = true
        api.fetch("/user/\(userID)", as: UsuarioDetalle.self) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let detalle):
                    self?.clases = detalle.clases_impartidas ?? []
                case .failure(let err):
                    self?.mensaje = "Error cargando clases: \(err.localizedDescription)"
                }
            }
        }
    }

    func cargarTareasPorClase(claseID: Int) {
        isLoading = true
        api.fetch("/tareas/clase/\(claseID)", as: [TareaOut].self) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let t): self?.tareas = t
                case .failure(let err): self?.mensaje = "Error: \(err.localizedDescription)"
                }
            }
        }
    }

    // Inscribir alumno -> uso de postJSONNoDecode (no decodificamos body)
    func inscribirAlumno(alumno_id: Int, clase_id: Int, completion: ((Result<Void, Error>) -> Void)? = nil) {
        isLoading = true
        mensaje = ""
        let body: [String: Any] = ["alumno_id": alumno_id, "clase_id": clase_id]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            isLoading = false; mensaje = "Error preparando datos"; completion?(.failure(NSError()))
            return
        }
        api.postJSONNoDecode("/inscripciones/", jsonData: jsonData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.mensaje = "Alumno inscrito con éxito"
                    self?.alumnoIdEscaneado = nil
                    self?.alumnoNombre = nil
                    completion?(.success(()))
                case .failure(let err):
                    self?.mensaje = "Error: \(err.localizedDescription)"
                    completion?(.failure(err))
                }
            }
        }
    }

    // Marcar asistencia rápida -> postJSONNoDecode
    func marcarAsistenciaRapida(alumno_id: Int, clase_id: Int, fecha: Date, completion: ((Result<Void, Error>) -> Void)? = nil) {
        isLoading = true
        mensaje = ""
        let fechaStr = ISO8601DateFormatter().string(from: fecha)
        let dict: [String: Any] = [
            "tema": "Entrada por QR",
            "fecha_clase": fechaStr,
            "id_clase": clase_id,
            "id_alumno": alumno_id
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            isLoading = false; mensaje = "Error preparando datos"; completion?(.failure(NSError()))
            return
        }
        api.postJSONNoDecode("/asistencias/", jsonData: jsonData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.mensaje = "Asistencia marcada con éxito"
                    self?.alumnoIdEscaneado = nil
                    self?.alumnoNombre = nil
                    completion?(.success(()))
                case .failure(let err):
                    self?.mensaje = "Error: \(err.localizedDescription)"
                    completion?(.failure(err))
                }
            }
        }
    }

    // Crear entrega con PDF "Revisada en clase" y registrar alumno_id en multipart
    func crearEntregaYCalificar(alumno_id: Int, tarea_id: Int) {
        mensaje = ""
        isLoading = true

        guard let pdfData = PDFGenerator.crearPDFRevisionEnClase() else {
            mensaje = "Error al crear el PDF"
            isLoading = false
            return
        }

        let fields: [String: String] = [
            "alumno_id": "\(alumno_id)",
            "nota": "Revisada en clase"
        ]

        api.postMultipartNoDecode("/entregas/tarea/\(tarea_id)", fields: fields, fileFieldName: "file", filename: "revision_en_clase.pdf", fileData: pdfData, mimeType: "application/pdf") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.mensaje = "Entrega creada, cargando para calificar..."
                    // Intentar cargar la entrega recién creada
                    self?.cargarEntregaParaCalificar(alumno_id: alumno_id, tarea_id: tarea_id)
                case .failure(let err):
                    self?.mensaje = "Error al crear entrega: \(err.localizedDescription)"
                }
            }
        }
    }

    func cargarEntregaParaCalificar(alumno_id: Int, tarea_id: Int) {
        isLoading = true
        api.fetch("/entregas/tarea/\(tarea_id)", as: [Entrega].self) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let todasEntregas):
                    if let entrega = todasEntregas.filter({ $0.alumno.id == alumno_id }).last {
                        self?.entregaCreada = entrega
                        self?.showCalificarDirecto = true
                    } else {
                        self?.mensaje = "No se encontró entrega del alumno"
                    }
                case .failure(let err):
                    self?.mensaje = "Error al cargar entregas: \(err.localizedDescription)"
                }
            }
        }
    }

    func actualizarEntrega(entregaId: Int, calificacion: Float, comentarios: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let json: [String: Any] = ["calificacion": calificacion, "comentarios": comentarios]
        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            completion?(.failure(NSError()))
            return
        }
        isLoading = true
        api.postJSONNoDecode("/entregas/\(entregaId)", jsonData: data) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.mensaje = "Calificación guardada con éxito"
                    self?.showCalificarDirecto = false
                    self?.alumnoIdEscaneado = nil
                    self?.alumnoNombre = nil
                    self?.entregaCreada = nil
                    completion?(.success(()))
                case .failure(let err):
                    self?.mensaje = "Error: \(err.localizedDescription)"
                    completion?(.failure(err))
                }
            }
        }
    }
}
