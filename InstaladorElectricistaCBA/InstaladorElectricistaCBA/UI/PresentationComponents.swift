import SwiftUI

// MARK: - Elementos visuales compartidos por los cuatro pasos

enum StatusTone { case complete, pending, invalid }

struct StatusMessage: View {
    let text: String
    let tone: StatusTone

    private var color: Color {
        switch tone { case .complete: .green; case .pending: .orange; case .invalid: .red }
    }
    private var symbol: String {
        switch tone {
        case .complete: "checkmark.circle.fill"
        case .pending: "exclamationmark.circle"
        case .invalid: "exclamationmark.triangle.fill"
        }
    }
    var body: some View { Label(text, systemImage: symbol).foregroundStyle(color).fixedSize(horizontal: false, vertical: true) }
}

struct LabeledInput: View {
    let title: String
    @Binding var text: String
    var unit: String? = nil
    var prompt = "Ingresá un valor"
    var decimalInput = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            HStack {
                TextField(title, text: $text, prompt: Text(prompt))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    #if os(iOS)
                    .keyboardType(decimalInput ? .decimalPad : .default)
                    .toolbar {
                        if decimalInput && isFocused {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Listo") { isFocused = false }
                            }
                        }
                    }
                    #endif
                    .accessibilityLabel(unit.map { "\(title), \($0)" } ?? title)
                if let unit { Text(unit).foregroundStyle(.secondary) }
            }
        }
    }
}

struct RegulatoryDisclosure<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8, content: content).font(.footnote)
        } label: {
            Label("Ver criterio normativo", systemImage: "info.circle").font(.subheadline)
        }
    }
}

struct ProjectStepHeader: View {
    let step: ProjectStep
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text(step.indicator).font(.subheadline).foregroundStyle(.secondary)
                ProgressView(value: Double(step.rawValue), total: 4).accessibilityLabel(step.indicator)
                Text(step.subtitle)
            }.padding(.vertical, 4)
        }
    }
}
