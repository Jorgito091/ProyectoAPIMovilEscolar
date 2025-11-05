import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRView: View {
    let alumnoID: Int
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding(.trailing, 3)
            .padding(.top, 3)

            Text("Mi código QR")
                .font(.title2)
                .bold()

            Image(uiImage: generateQR(from: "{\"alumno_id\":\(alumnoID)}"))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)
                .padding(30)
                .background(Color.white)
                .cornerRadius(22)
                .shadow(radius: 8, y: 4)

            Text("Muestra este código al maestro para que te inscriba a una clase.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private func generateQR(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        let transform = CGAffineTransform(scaleX: 18, y: 18)
        if let outputImage = filter.outputImage?.transformed(by: transform),
           let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
