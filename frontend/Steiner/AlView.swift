import SwiftUI

struct AlView: View {
    let accessToken: String
    let alumnoID: Int

    let cafe = Color(red: 71/255, green: 53/255, blue: 37/255)
    let beige = Color(red: 230/255, green: 220/255, blue: 200/255)
    let cafeOscuro = Color(red: 51/255, green: 37/255, blue: 24/255)

    var body: some View {
        ZStack {
            cafeOscuro.ignoresSafeArea()
            VStack(spacing: 28) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(beige)
                    Text("¡Bienvenido, Alumno!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(beige)
                }
                .padding(.top, 12)

                MinimalSectionButtonCafe(
                    text: "Ver tareas",
                    selected: true,
                    color: cafe,
                    selectedColor: cafeOscuro,
                    action: {}
                )
                .padding(.horizontal)

                Divider().background(cafe.opacity(0.25))

                VerTareasView(accessToken: accessToken, alumnoID: alumnoID)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(beige.opacity(0.90))
                    .cornerRadius(18)
                    .shadow(color: cafeOscuro.opacity(0.08), radius: 8, y: 2)

                Spacer()
            }
            .padding(.top, 28)
            .padding(.horizontal)
        }
    }
}

struct MinimalSectionButtonCafe: View {
    var text: String
    var selected: Bool
    var color: Color
    var selectedColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(selected ? Color.white : selectedColor)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selected ? color : Color.white.opacity(0.7))
                .cornerRadius(12)
                .shadow(color: selected ? color.opacity(0.18) : .clear, radius: 4, y: 1)
                .animation(.easeInOut, value: selected)
        }
    }
}
