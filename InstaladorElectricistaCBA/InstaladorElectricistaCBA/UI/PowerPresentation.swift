import Foundation

// MARK: - Formato local sin modificar la precisión del dominio

enum PowerPresentation {
    static func number(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "es_AR")).grouping(.automatic).precision(.fractionLength(0...2)))
    }

    static func factor(_ value: Double) -> String {
        value.formatted(.number.locale(Locale(identifier: "es_AR")).precision(.significantDigits(2...8)))
    }

    static func expression(_ calculation: LoadPowerCalculation) -> String {
        guard let multiplier = calculation.wattsPerDeclaredUnit, let factor = calculation.powerFactorUsed else {
            return "Potencia aparente declarada"
        }
        let load = calculation.declaredLoad
        if load.unit == .watt { return "\(load.value.formatted(.number.locale(Locale(identifier: "es_AR")))) W ÷ \(factor.displayValue)" }
        return "\(load.value.formatted(.number.locale(Locale(identifier: "es_AR")))) \(load.unit.rawValue) × \(number(multiplier)) W/\(load.unit.rawValue) ÷ \(factor.displayValue)"
    }
}
