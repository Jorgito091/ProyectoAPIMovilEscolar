import UIKit
import PDFKit

final class PDFGenerator {
    static func crearPDFRevisionEnClase(fecha: Date = Date()) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Sistema de Calificaciones",
            kCGPDFContextTitle: "Revisión en Clase"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let bodyFont = UIFont.systemFont(ofSize: 16)
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
            let titulo = "REVISIÓN EN CLASE"
            let titleSize = titulo.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageRect.width - titleSize.width) / 2, y: 100, width: titleSize.width, height: titleSize.height)
            titulo.draw(in: titleRect, withAttributes: titleAttributes)
            let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            let formatter = DateFormatter()
            formatter.dateStyle = .long; formatter.timeStyle = .short; formatter.locale = Locale(identifier: "es_MX")
            let contenido = """

            Esta tarea fue revisada presencialmente en clase.

            No se requirió entrega física del documento.

            Fecha de revisión: \(formatter.string(from: fecha))

            El profesor realizará la calificación correspondiente
            basándose en la revisión realizada en el aula.
            """
            let textRect = CGRect(x: 60, y: 200, width: pageRect.width - 120, height: pageRect.height - 300)
            contenido.draw(in: textRect, withAttributes: bodyAttributes)
        }
        return data
    }
}
