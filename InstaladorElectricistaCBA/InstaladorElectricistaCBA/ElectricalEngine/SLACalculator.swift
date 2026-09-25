// RULE-SLA-001 — AEA 90364-7-770:2017, 770.7.3.
// Pure arithmetic; electrification thresholds belong to the regulatory layer.
nonisolated enum SLACalculator {
    static func calculate(covered: SquareMeters, semiCovered: SquareMeters) throws -> SquareMeters {
        try SquareMeters(covered.value + 0.5 * semiCovered.value)
    }
}
