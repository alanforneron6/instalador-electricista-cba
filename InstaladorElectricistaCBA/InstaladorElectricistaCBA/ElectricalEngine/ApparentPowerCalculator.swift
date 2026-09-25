nonisolated enum ApparentPowerCalculator {
    static let criterionID = "CALC-APPARENT-POWER-001"

    // Criterio explícito del proyecto: HP × 746 W/HP, sin rendimiento supuesto.
    private static let wattsPerHorsepower = 746.0
    private static let wattsPerKilowatt = 1000.0

    static func calculate(_ load: DeclaredLoad, powerFactor: PowerFactor? = nil) -> Result<LoadPowerCalculation, DemandCalculationError> {
        do {
            if load.unit == .voltAmpere {
                return .success(LoadPowerCalculation(declaredLoad: load, wattsPerDeclaredUnit: nil,
                    activePowerWatts: nil, powerFactorUsed: nil,
                    apparentPower: try ApparentPower(voltAmperes: load.value), criterionID: criterionID))
            }
            guard let powerFactor else { return .failure(.missingPowerFactor) }
            let multiplier: Double
            switch load.unit {
            case .watt: multiplier = 1
            case .kilowatt: multiplier = wattsPerKilowatt
            case .horsepower: multiplier = wattsPerHorsepower
            case .voltAmpere: preconditionFailure("VA se resuelve antes de la conversión activa.")
            }
            let watts = load.value * multiplier
            let apparentPower = try ApparentPower(voltAmperes: watts / powerFactor.value)
            return .success(LoadPowerCalculation(declaredLoad: load, wattsPerDeclaredUnit: multiplier,
                activePowerWatts: watts, powerFactorUsed: powerFactor, apparentPower: apparentPower, criterionID: criterionID))
        } catch { return .failure(.numericOverflow) }
    }
}
