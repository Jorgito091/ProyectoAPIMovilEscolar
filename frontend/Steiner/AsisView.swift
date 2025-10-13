import SwiftUI

struct AsisView: View {
    @State private var selectedGrupo: String? = nil
    @State private var selectedFecha: String? = nil

    let gruposDemo = ["Programación Avanzada", "Pulso y Ritmo"]
    let fechasDemo = ["2025-10-07", "2025-10-08", "2025-10-09"]

    let alumnosDemo: [String: [String]] = [
        "Programación Avanzada": [
            "Ana López", "Luis Pérez", "Carlos Gómez", "Sofía Martínez", "Jorge Torres"
        ],
        "Pulso y Ritmo": [
            "María Rivera", "Pedro Sánchez", "Lucía Díaz", "Mateo Hernández", "Elena Castro"
        ]
    ]

    // Estado de asistencias solo para mostrar el diseño visual
    @State private var asistenciaEstado: [String: [String: Bool]] = [
        "Programación Avanzada": [
            "Ana López": false,
            "Luis Pérez": false,
            "Carlos Gómez": false,
            "Sofía Martínez": false,
            "Jorge Torres": false
        ],
        "Pulso y Ritmo": [
            "María Rivera": false,
            "Pedro Sánchez": false,
            "Lucía Díaz": false,
            "Mateo Hernández": false,
            "Elena Castro": false
        ]
    ]

    var body: some View {
        VStack(spacing: 22) {
            Text("Registro de Asistencias")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
                .padding(.top, 16)

            Picker("Selecciona un grupo", selection: $selectedGrupo) {
                ForEach(gruposDemo, id: \.self) { grupo in
                    Text(grupo)
                        .font(.headline)
                        .tag(grupo as String?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)

            Picker("Selecciona una fecha", selection: $selectedFecha) {
                ForEach(fechasDemo, id: \.self) { fecha in
                    Text(fecha)
                        .tag(fecha as String?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 10)

            if let grupo = selectedGrupo, let alumnos = alumnosDemo[grupo], selectedFecha != nil {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Alumnos en \(grupo) (\(selectedFecha ?? "")):")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                        .padding(.bottom, 8)

                    // Tabla con nombre y botones
                    List(alumnos, id: \.self) { alumno in
                        HStack {
                            Text(alumno)
                                .font(.headline)
                            Spacer()
                            Button {
                                asistenciaEstado[grupo]?[alumno] = true
                            } label: {
                                Image(systemName: asistenciaEstado[grupo]?[alumno] == true ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            .buttonStyle(BorderlessButtonStyle())

                            Button {
                                asistenciaEstado[grupo]?[alumno] = false
                            } label: {
                                Image(systemName: asistenciaEstado[grupo]?[alumno] == false ? "xmark.circle.fill" : "circle")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .frame(maxHeight: 350)
                }
                .padding(.horizontal)
            } else {
                Text("Selecciona un grupo y una fecha para ver los alumnos.")
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}
