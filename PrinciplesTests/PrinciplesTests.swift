//
//  PrinciplesTests.swift
//  PrinciplesTests
//
//  Created by Codex on 2026-03-10.
//

import Foundation
import Testing
@testable import Principles

struct PrinciplesTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    @Test func streakStaysAliveWhenYesterdayWasCompleted() async throws {
        let now = Date(timeIntervalSince1970: 1_773_144_800) // 2026-03-10 12:00:00 UTC
        let march7 = Date(timeIntervalSince1970: 1_772_884_800)
        let march8 = Date(timeIntervalSince1970: 1_772_971_200)
        let march9 = Date(timeIntervalSince1970: 1_773_057_600)

        let snapshot = PrincipleAnalytics.snapshot(
            checkIns: [march7, march8, march9],
            createdAt: march7,
            targetDays: 21,
            graduatedAt: nil,
            now: now,
            calendar: calendar
        )

        #expect(snapshot.currentStreak == 3)
        #expect(snapshot.completedToday == false)
        #expect(snapshot.completedYesterday == true)
    }

    @Test func graduationRequiresTwentyOneConsecutiveDays() async throws {
        let now = Date(timeIntervalSince1970: 1_773_144_800) // 2026-03-10 12:00:00 UTC
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -20, to: today) ?? today
        let checkIns = (0..<21).compactMap { index in
            calendar.date(byAdding: .day, value: index, to: start)
        }

        let snapshot = PrincipleAnalytics.snapshot(
            checkIns: checkIns,
            createdAt: start,
            targetDays: 21,
            graduatedAt: nil,
            now: now,
            calendar: calendar
        )

        #expect(snapshot.currentStreak == 21)
        #expect(snapshot.longestStreak == 21)
        #expect(snapshot.hasGraduated == true)
        #expect(snapshot.remainingToGraduate == 0)
    }
}
