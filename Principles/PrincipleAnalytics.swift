//
//  PrincipleAnalytics.swift
//  Principles
//
//  Created by Codex on 2026-03-10.
//

import Foundation

struct PrincipleAnalyticsSnapshot: Equatable {
    let normalizedDays: [Date]
    let currentStreak: Int
    let longestStreak: Int
    let totalCheckIns: Int
    let activeDayCount: Int
    let completionRate: Double
    let lastCheckIn: Date?
    let completedToday: Bool
    let completedYesterday: Bool
    let remainingToGraduate: Int
    let progressFraction: Double
    let hasGraduated: Bool
}

struct PrincipleDayState: Identifiable, Equatable {
    let id: Date
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
}

enum PrincipleAnalytics {
    static func normalizedDays(
        from checkIns: [Date],
        calendar: Calendar = .current
    ) -> [Date] {
        Array(
            Set(checkIns.map { calendar.startOfDay(for: $0) })
        )
        .sorted()
    }

    static func timelineDates(
        count: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - (count - 1), to: today)
        }
    }

    static func timelineState(
        checkIns: [Date],
        count: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PrincipleDayState] {
        let completedDays = Set(normalizedDays(from: checkIns, calendar: calendar))
        return timelineDates(count: count, now: now, calendar: calendar).map { date in
            PrincipleDayState(
                id: date,
                date: date,
                isCompleted: completedDays.contains(date),
                isToday: calendar.isDate(date, inSameDayAs: now)
            )
        }
    }

    static func snapshot(
        checkIns: [Date],
        createdAt: Date,
        targetDays: Int,
        graduatedAt: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> PrincipleAnalyticsSnapshot {
        let days = normalizedDays(from: checkIns, calendar: calendar)
        let totalCheckIns = days.count
        let currentStreak = currentStreak(from: days, now: now, calendar: calendar)
        let longestStreak = longestStreak(from: days, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let activeStart = calendar.startOfDay(for: min(createdAt, now))
        let activeDayCount = max(
            1,
            (calendar.dateComponents([.day], from: activeStart, to: today).day ?? 0) + 1
        )
        let hasGraduated = graduatedAt != nil || currentStreak >= targetDays

        return PrincipleAnalyticsSnapshot(
            normalizedDays: days,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCheckIns: totalCheckIns,
            activeDayCount: activeDayCount,
            completionRate: Double(totalCheckIns) / Double(activeDayCount),
            lastCheckIn: days.last,
            completedToday: days.contains(today),
            completedYesterday: days.contains(yesterday),
            remainingToGraduate: hasGraduated ? 0 : max(0, targetDays - currentStreak),
            progressFraction: hasGraduated
                ? 1
                : min(Double(currentStreak) / Double(max(targetDays, 1)), 1),
            hasGraduated: hasGraduated
        )
    }

    static func currentStreak(
        from days: [Date],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        guard let latest = days.last else {
            return 0
        }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        guard latest == today || latest == yesterday else {
            return 0
        }

        return streakEnding(at: latest, in: days, calendar: calendar)
    }

    static func longestStreak(
        from days: [Date],
        calendar: Calendar = .current
    ) -> Int {
        guard !days.isEmpty else {
            return 0
        }

        var best = 1
        var running = 1

        for index in 1..<days.count {
            let previous = days[index - 1]
            let current = days[index]
            let expected = calendar.date(byAdding: .day, value: 1, to: previous)

            if current == expected {
                running += 1
            } else {
                best = max(best, running)
                running = 1
            }
        }

        return max(best, running)
    }

    private static func streakEnding(
        at endDate: Date,
        in days: [Date],
        calendar: Calendar
    ) -> Int {
        let daySet = Set(days)
        var streak = 0
        var cursor: Date? = endDate

        while let current = cursor, daySet.contains(current) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: current)
        }

        return streak
    }
}
