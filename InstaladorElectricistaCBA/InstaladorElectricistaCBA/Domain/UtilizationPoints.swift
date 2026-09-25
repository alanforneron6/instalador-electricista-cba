nonisolated enum UtilizationPointKind: CaseIterable, Hashable {
    case generalLighting, generalUseOutlet, fixedApplianceModule
}

nonisolated struct UtilizationPoints {
    private var counts: [UtilizationPointKind: Int] = [:]
    enum ValidationError: Error { case negativeCount }

    func count(for kind: UtilizationPointKind) -> Int { counts[kind, default: 0] }

    mutating func setCount(_ count: Int, for kind: UtilizationPointKind) throws {
        guard count >= 0 else { throw ValidationError.negativeCount }
        counts[kind] = count
    }
}

nonisolated struct UtilizationPointRequirement {
    let kind: UtilizationPointKind
    let minimumCount: Int
}

nonisolated enum ComplianceStatus: Equatable {
    case notApplicable
    case conforming
    case missing(Int)
}

nonisolated struct PointComparison {
    let kind: UtilizationPointKind
    let required: Int?
    let projected: Int
    let status: ComplianceStatus

    static func compare(_ points: UtilizationPoints, with requirements: [UtilizationPointRequirement]) -> [Self] {
        UtilizationPointKind.allCases.map { kind in
            let required = requirements.first { $0.kind == kind }?.minimumCount
            let projected = points.count(for: kind)
            let status: ComplianceStatus
            if let required {
                status = projected >= required ? .conforming : .missing(required - projected)
            } else {
                status = .notApplicable
            }
            return Self(kind: kind, required: required, projected: projected, status: status)
        }
    }
}
