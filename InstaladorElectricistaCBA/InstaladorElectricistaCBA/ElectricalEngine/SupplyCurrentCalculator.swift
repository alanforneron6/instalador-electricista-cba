import Foundation

nonisolated enum SupplyCurrentCalculator {
    static let criterionID = "CALC-SUPPLY-CURRENT-001"

    static func monophase(apparentPower: ApparentPower) throws -> SupplyCurrentCalculation {
        let volts = CordobaSupplyProfile.current.phaseNeutralVolts
        return SupplyCurrentCalculation(basis: .monophaseHypothesis, apparentPower: apparentPower,
                                        voltageVolts: volts,
                                        current: try ElectricCurrent(amperes: apparentPower.voltAmperes / volts),
                                        criterionID: criterionID)
    }

    // Sólo receptor equilibrado: nunca sustituye la corriente seccional del proyecto.
    static func balancedThreePhaseReceiver(apparentPower: ApparentPower) throws -> SupplyCurrentCalculation {
        let volts = CordobaSupplyProfile.current.phasePhaseVolts
        return SupplyCurrentCalculation(basis: .balancedThreePhaseReceiver, apparentPower: apparentPower,
                                        voltageVolts: volts,
                                        current: try ElectricCurrent(amperes: apparentPower.voltAmperes / (sqrt(3) * volts)),
                                        criterionID: criterionID)
    }
}
