import Foundation

struct GamificationProfile: Codable, Equatable {
    var xp: Int = 0
    var dailyStreak: Int = 0
    var longestStreak: Int = 0
    var lastActiveDay: Date?
    var totalRoleplays: Int = 0
    var totalContacts: Int = 0

    var level: Int { max(1, xp / 250 + 1) }
    var levelTitle: String {
        switch level {
        case 1...2: return "Rookie Closer"
        case 3...5: return "Pipeline Pro"
        case 6...9: return "Deal Maker"
        case 10...14: return "Sales Elite"
        default: return "Top 1% Closer"
        }
    }
}

enum GamificationEvent {
    case roleplayComplete(score: Int)
    case crmContact
    case leadAdded
    case dealWon
    case dailyOpen
}

@MainActor
@Observable
final class GamificationService {
    private(set) var profile = GamificationProfile()
    private var storageKey: String { "salescoach_gamification" }

    func load(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode(GamificationProfile.self, from: data) else {
            profile = GamificationProfile()
            record(.dailyOpen, userId: userId)
            return
        }
        profile = stored
        record(.dailyOpen, userId: userId)
    }

    func record(_ event: GamificationEvent, userId: String) {
        switch event {
        case .roleplayComplete(let score):
            profile.totalRoleplays += 1
            profile.xp += 40 + score / 2
        case .crmContact:
            profile.totalContacts += 1
            profile.xp += 15
        case .leadAdded:
            profile.xp += 25
        case .dealWon:
            profile.xp += 100
        case .dailyOpen:
            let today = Calendar.current.startOfDay(for: .now)
            if let last = profile.lastActiveDay, Calendar.current.isDate(last, inSameDayAs: today) {
                break
            }
            updateStreak()
            profile.xp += 5
        }
        save(for: userId)
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: .now)
        if let last = profile.lastActiveDay {
            let lastDay = Calendar.current.startOfDay(for: last)
            if lastDay == today { return }
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today),
               lastDay == yesterday {
                profile.dailyStreak += 1
            } else {
                profile.dailyStreak = 1
            }
        } else {
            profile.dailyStreak = 1
        }
        profile.lastActiveDay = today
        profile.longestStreak = max(profile.longestStreak, profile.dailyStreak)
    }

    private func save(for userId: String) {
        let key = "\(storageKey)_\(userId)"
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
