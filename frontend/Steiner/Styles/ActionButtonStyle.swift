import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    var background: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(background.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}
