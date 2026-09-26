import SwiftUI

struct RoomsView: View {
    @Binding var rooms: [Room]
    let grade: ElectrificationGrade
    @State private var showingForm = false
    @State private var feedback: String?
    @State private var feedbackID = UUID()

    var body: some View {
        Section {
            Text("Ambientes cargados: \(rooms.count)").font(.headline)
            if let feedback { StatusMessage(text: feedback, tone: .complete) }
            if rooms.isEmpty { Text("Todavía no agregaste ambientes.").foregroundStyle(.secondary) }
        }
        ForEach(rooms) { room in
            Section {
                let presentation = RoomPresentation(room: room, grade: grade)
                VStack(alignment: .leading, spacing: 8) {
                    Text(room.name).font(.headline)
                    Text(RoomPresentation.summary(room))
                    StatusMessage(text: presentation.completion.text, tone: presentation.completion.tone)
                }.padding(.vertical, 4)
                DisclosureGroup("Ver cantidades y detalles") {
                    Text(room.type.displayName)
                    if let area = room.area { Text("Superficie: \(area.value.formatted()) m²") }
                    if let length = room.length { Text("Longitud: \(length.value.formatted()) m") }
                    ForEach(presentation.comparisons, id: \.kind) { item in
                        VStack(alignment: .leading) {
                            Text(item.kind.inputTitle).font(.subheadline.bold())
                            if let required = item.required { Text("Mínimo requerido: \(item.kind.quantityText(required)) · \(item.kind.projectedText(item.projected))") }
                            else { Text("Sin mínimo aplicable · \(item.kind.projectedText(item.projected))") }
                            PointComplianceView(kind: item.kind, status: item.status)
                        }.padding(.vertical, 4)
                    }
                    if presentation.completion == .needsInformation {
                        Text("Quitá y volvé a agregar el ambiente con la dimensión requerida por el grado actual.")
                    }
                    RoomCriterionView(notes: presentation.notes)
                    Button("Quitar ambiente", role: .destructive) { rooms.removeAll { $0.id == room.id } }
                }
            }
        }
        Section {
            Button { showingForm = true } label: { Label("Agregar ambiente", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 44) }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingForm) {
                    AddRoomView(grade: grade) { room in
                        rooms.append(room)
                        feedback = "\(room.name) agregada"
                        feedbackID = UUID()
                    }
                }
            RoomCriterionView(notes: [])
        }
        .task(id: feedbackID) {
            guard feedback != nil else { return }
            do { try await Task.sleep(for: .milliseconds(1500)) }
            catch { return }
            feedback = nil
        }
    }
}

// MARK: - Alta con comparación inmediata de puntos

private struct AddRoomView: View {
    let grade: ElectrificationGrade
    let onAdd: (Room) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft = RoomForm()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledInput(title: "Nombre del ambiente", text: $draft.name, prompt: "Por ejemplo: Cocina")
                    Picker("Tipo de ambiente", selection: $draft.type) {
                        ForEach(RoomType.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    switch RoomMinimumPointsRule.dimension(for: draft.type, grade: grade) {
                    case .area: LabeledInput(title: "Superficie", text: $draft.dimension, unit: "m²", decimalInput: true)
                    case .length: LabeledInput(title: "Longitud", text: $draft.dimension, unit: "m", decimalInput: true)
                    case .none: EmptyView()
                    }
                }
                Section(draft.type == .kitchen ? "Bocas y módulos proyectados" : "Bocas proyectadas") {
                    Text("Indicá las bocas que tendrá este ambiente. En cocina, registrá también los módulos para equipos fijos por separado.")
                    let presentation = RoomPresentation(draft: draft, grade: grade)
                    pointControl(.generalLighting, text: $draft.iug, presentation: presentation)
                    pointControl(.generalUseOutlet, text: $draft.tug, presentation: presentation)
                    if draft.type == .kitchen {
                        pointControl(.fixedApplianceModule, text: $draft.modules, presentation: presentation)
                        Text("Pueden compartir una misma boca con otros tomacorrientes. No representan bocas adicionales ni cargas independientes.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if presentation.comparisons.isEmpty {
                        StatusMessage(text: presentation.completion.text, tone: presentation.completion.tone)
                    }
                    RoomCriterionView(notes: presentation.notes)
                }
                Section {
                    Button {
                        do {
                            let room = try draft.makeRoom(grade: grade)
                            onAdd(room)
                            draft = RoomForm(); errorMessage = nil
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    } label: { Text("Agregar ambiente").frame(maxWidth: .infinity, minHeight: 44) }
                    .buttonStyle(.borderedProminent)
                    if let errorMessage { StatusMessage(text: errorMessage, tone: .invalid) }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Agregar ambiente")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } } }
        }
    }

    private func pointControl(_ kind: UtilizationPointKind, text: Binding<String>, presentation: RoomPresentation) -> some View {
        let comparison = presentation.comparisons.first { $0.kind == kind }
        let count = Binding<Int>(get: { Int(text.wrappedValue) ?? 0 }, set: { text.wrappedValue = String($0) })
        return VStack(alignment: .leading, spacing: 6) {
            Text(kind.inputTitle).font(.subheadline.bold())
            if let comparison {
                if let minimum = comparison.required { Text("Mínimo requerido: \(kind.quantityText(minimum))").font(.footnote) }
                else { Text("Sin mínimo requerido para este ambiente.").font(.footnote) }
            } else { Text("Mínimo requerido: pendiente de dimensión").font(.footnote) }
            Stepper(value: count, in: 0...Int.max) { Text(kind.projectedText(count.wrappedValue)) }
                .accessibilityLabel(kind.inputTitle)
                .accessibilityValue(kind.projectedText(count.wrappedValue))
            if let comparison { PointComplianceView(kind: kind, status: comparison.status) }
        }.padding(.vertical, 6)
    }
}

private struct PointComplianceView: View {
    let kind: UtilizationPointKind
    let status: ComplianceStatus
    var body: some View {
        switch status {
        case .conforming: StatusMessage(text: "Cumple", tone: .complete)
        case .missing(let count): StatusMessage(text: kind.missingText(count), tone: .pending)
        case .notApplicable: Text(kind == .fixedApplianceModule ? "La regla no prohíbe instalar estos módulos." : "La regla no prohíbe instalar este tipo de boca.").font(.footnote).foregroundStyle(.secondary)
        }
    }
}

private struct RoomCriterionView: View {
    let notes: [RoomMinimumPointsRule.Note]
    var body: some View {
        if notes.contains(.largeBedroomElevatedCriterion) {
            Text("Este dormitorio tiene un criterio particular por superar los 36 m².").font(.footnote)
        }
        RegulatoryDisclosure {
            Text("Bocas y módulos mínimos por ambiente").font(.headline)
            Text(RoomMinimumPointsRule.source)
            Text("Referencia interna: \(RoomMinimumPointsRule.ruleID)").foregroundStyle(.secondary)
            Text("La revisión se limita a los mínimos de bocas y módulos; no verifica ubicación ni otras condiciones de la instalación.")
            ForEach(notes.indices, id: \.self) { index in
                switch notes[index] {
                case .largeBedroomElevatedCriterion:
                    Text("En viviendas de superficie inferior a 130 m² con dormitorios mayores a 36 m², las bocas mínimas correspondientes se tratan con criterio de grado elevado. Esta nota no modifica el grado del proyecto.")
                }
            }
        }
    }
}
