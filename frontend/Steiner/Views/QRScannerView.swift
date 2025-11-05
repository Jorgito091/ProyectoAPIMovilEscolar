import SwiftUI
import CodeScanner

struct QRScannerView: View {
    var completion: (Result<ScanResult, ScanError>) -> Void

    var body: some View {
        CodeScannerView(codeTypes: [.qr]) { result in
            completion(result)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
