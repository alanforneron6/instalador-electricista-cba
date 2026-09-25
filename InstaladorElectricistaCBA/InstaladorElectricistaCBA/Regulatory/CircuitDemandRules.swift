// MARK: - DPMS residencial — AEA 90364-7-770:2017, 770.8.1, Tabla 770.8.I

nonisolated struct RegulatoryDemandCalculation: Equatable {
    let ruleID: String
    let source: String
    let basePower: ApparentPower
    let factor: Double
    let minimumDemand: ApparentPower
    let knownDemand: ApparentPower?
    let adoptedDemand: ApparentPower

    fileprivate init(ruleID: String, baseVA: Double, factor: Double, knownDemand: ApparentPower?) throws {
        self.ruleID = ruleID
        self.source = "AEA 90364-7-770:2017 · 770.8.1 · Tabla 770.8.I"
        self.basePower = try ApparentPower(voltAmperes: baseVA)
        self.factor = factor
        self.minimumDemand = try ApparentPower(voltAmperes: baseVA * factor)
        self.knownDemand = knownDemand
        // La demanda conocida puede superar el mínimo; nunca lo reduce.
        self.adoptedDemand = try ApparentPower(voltAmperes: max(minimumDemand.voltAmperes, knownDemand?.voltAmperes ?? 0))
    }
}

nonisolated enum IUGDemandRule {
    static let ruleID = "RULE-DPMS-IUG-001"
    static let voltAmperesPerPoint = 60.0
    static let factorNumerator = 2.0
    static let factorDenominator = 3.0
    static let demandFactor = factorNumerator / factorDenominator

    // Alcance actual: IUG sin tomacorrientes derivados.
    static func evaluate(pointCount: Int, knownDemand: ApparentPower? = nil) throws -> RegulatoryDemandCalculation {
        guard pointCount >= 0 else { throw DemandCalculationError.invalidPointCount }
        return try RegulatoryDemandCalculation(ruleID: ruleID, baseVA: Double(pointCount) * voltAmperesPerPoint,
                                               factor: demandFactor, knownDemand: knownDemand)
    }
}

nonisolated enum TUGDemandRule {
    static let ruleID = "RULE-DPMS-TUG-001"
    static let minimumVoltAmperes = 2200.0

    static func evaluate(knownDemand: ApparentPower? = nil) throws -> RegulatoryDemandCalculation {
        try RegulatoryDemandCalculation(ruleID: ruleID, baseVA: minimumVoltAmperes, factor: 1, knownDemand: knownDemand)
    }
}

nonisolated enum TUEDemandRule {
    static let ruleID = "RULE-DPMS-TUE-001"
    static let minimumVoltAmperes = 3300.0

    static func evaluate(knownDemand: ApparentPower? = nil) throws -> RegulatoryDemandCalculation {
        try RegulatoryDemandCalculation(ruleID: ruleID, baseVA: minimumVoltAmperes, factor: 1, knownDemand: knownDemand)
    }
}
