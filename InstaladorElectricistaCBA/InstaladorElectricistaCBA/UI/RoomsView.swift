import SwiftUI

struct RoomsView: View {
    @Binding var rooms: [Room]
    let grade: ElectrificationGrade
    @State private var draft = RoomForm()
    @State private var errorMessage: String?

    var body: some View {
        Section("Agregar ambiente") {
            Text("Grado preliminar: \(grade.displayName)")
            TextField("Nombre del ambiente", text: $draft.name)
            Picker("Tipo", selection: $draft.type) {
                ForEach(RoomType.allCases, id: \.self) { Text($0.displayName).tag($0) }
            }
            switch RoomMinimumPointsRule.dimension(for: draft.type, grade: grade) {
            case .area: TextField("Superficie (m²)", text: $draft.dimension)
            case .length: TextField("Longitud (m)", text: $draft.dimension)
            case .none: EmptyView()
            }
            TextField("Bocas IUG proyectadas", text: $draft.iug)
            TextField("Bocas TUG proyectadas", text: $draft.tug)
            if draft.type == .kitchen {
                TextField("Módulos para electrodomésticos fijos", text: $draft.modules)
            }
            Button("Agregar ambiente") {
                do {
                    rooms.append(try draft.makeRoom(grade: grade))
                    draft = RoomForm()
                    errorMessage = nil
                } catch { errorMessage = error.localizedDescription }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        ForEach(rooms) { room in
            Section(room.name) {
                Text(room.type.displayName)
                Text("GE: \(grade.displayName)")
                if let area = room.area { Text("Superficie: \(area.value.formatted()) m²") }
                if let length = room.length { Text("Longitud: \(length.value.formatted()) m") }
                comparison(room)
                Button("Quitar ambiente", role: .destructive) { rooms.removeAll { $0.id == room.id } }
            }
        }
        Section("Referencia de mínimos") {
            Text(RoomMinimumPointsRule.ruleID)
            Text(RoomMinimumPointsRule.source)
            Text("Conformidad limitada a puntos mínimos; no verifica ubicación ni otras condiciones de la instalación.")
        }
    }

    @ViewBuilder private func comparison(_ room: Room) -> some View {
        switch Result(catching: { try RoomMinimumPointsRule.evaluate(room, grade: grade) }) {
        case .success(let evaluation):
            let comparisons = PointComparison.compare(room.projectedPoints, with: evaluation.requirements)
            let hasMissingPoints = comparisons.contains {
                if case .missing = $0.status { return true }
                return false
            }
            Text(hasMissingPoints ? "No conforme: faltan puntos" : "Revisión de mínimos completada")
            ForEach(comparisons, id: \.kind) { item in
                VStack(alignment: .leading) {
                    Text(item.kind.displayName).font(.headline)
                    switch item.status {
                    case .notApplicable:
                        Text("Sin mínimo aplicable · Proyectado: \(item.projected)")
                        Text("La regla no prohíbe instalar este tipo de punto.")
                    case .conforming:
                        if let required = item.required {
                            Text("Mínimo: \(required) · Proyectado: \(item.projected)")
                        }
                        Text("Conforme")
                    case .missing(let count):
                        if let required = item.required {
                            Text("Mínimo: \(required) · Proyectado: \(item.projected) · Faltan: \(count)")
                        }
                        Text("No conforme")
                    }
                }
            }
            ForEach(evaluation.notes.indices, id: \.self) { index in
                switch evaluation.notes[index] {
                case .largeBedroomElevatedCriterion:
                    Text("Nota normativa: en viviendas de superficie inferior a 130 m² con dormitorios mayores a 36 m², los puntos mínimos correspondientes se tratan con criterio de grado elevado. Esta nota no modifica el grado del proyecto.")
                }
            }
        case .failure:
            Text("Pendiente de información: falta una dimensión requerida por el grado actual o su valor excede el rango admitido. Quitá y volvé a agregar el ambiente con los datos completos.")
        }
    }
}
