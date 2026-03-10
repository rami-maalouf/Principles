//
//  PrincipleModels.swift
//  Principles
//
//  Created by Codex on 2026-03-10.
//

import Foundation
import SwiftData

@Model
final class Principle {
    var id: UUID
    var title: String
    var principleDescription: String
    var createdAt: Date
    var updatedAt: Date
    var graduatedAt: Date?
    var archivedAt: Date?
    var targetDays: Int

    @Relationship(deleteRule: .cascade, inverse: \PrincipleCheckIn.principle)
    var checkIns: [PrincipleCheckIn]

    init(
        id: UUID = UUID(),
        title: String,
        principleDescription: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        graduatedAt: Date? = nil,
        archivedAt: Date? = nil,
        targetDays: Int = 21,
        checkIns: [PrincipleCheckIn] = []
    ) {
        self.id = id
        self.title = title
        self.principleDescription = principleDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.graduatedAt = graduatedAt
        self.archivedAt = archivedAt
        self.targetDays = targetDays
        self.checkIns = checkIns
    }
}

@Model
final class PrincipleCheckIn {
    var id: UUID
    var day: Date
    var createdAt: Date
    var principle: Principle?

    init(
        id: UUID = UUID(),
        day: Date,
        createdAt: Date = .now,
        principle: Principle? = nil
    ) {
        self.id = id
        self.day = day
        self.createdAt = createdAt
        self.principle = principle
    }
}

extension Principle {
    var isArchived: Bool {
        archivedAt != nil
    }

    var hasGraduated: Bool {
        graduatedAt != nil
    }

    func analytics(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> PrincipleAnalyticsSnapshot {
        PrincipleAnalytics.snapshot(
            checkIns: checkIns.map(\.day),
            createdAt: createdAt,
            targetDays: targetDays,
            graduatedAt: graduatedAt,
            now: now,
            calendar: calendar
        )
    }
}
