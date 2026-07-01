import Foundation

struct ContactIntel: Codable, Equatable {
    var interests: String
    var likes: String
    var kidsNames: String
    var familyNotes: String
    var conversationStarters: String

    init(
        interests: String = "",
        likes: String = "",
        kidsNames: String = "",
        familyNotes: String = "",
        conversationStarters: String = ""
    ) {
        self.interests = interests
        self.likes = likes
        self.kidsNames = kidsNames
        self.familyNotes = familyNotes
        self.conversationStarters = conversationStarters
    }

    var hasPersonalDetails: Bool {
        ![interests, likes, kidsNames, familyNotes, conversationStarters]
            .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var briefingFacts: [ContactIntelFact] {
        var facts: [ContactIntelFact] = []
        if !likes.isEmpty {
            facts.append(ContactIntelFact(icon: "heart.fill", label: "Likes", value: likes))
        }
        if !interests.isEmpty {
            facts.append(ContactIntelFact(icon: "sparkles", label: "Interests", value: interests))
        }
        if !kidsNames.isEmpty {
            facts.append(ContactIntelFact(icon: "figure.2.and.child.holdinghands", label: "Kids", value: kidsNames))
        }
        if !familyNotes.isEmpty {
            facts.append(ContactIntelFact(icon: "house.fill", label: "Family", value: familyNotes))
        }
        if !conversationStarters.isEmpty {
            facts.append(ContactIntelFact(icon: "bubble.left.and.bubble.right.fill", label: "Talk about", value: conversationStarters))
        }
        return facts
    }

    var notificationSnippet: String {
        briefingFacts.prefix(2).map(\.value).joined(separator: " · ")
    }
}

struct ContactIntelFact: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let label: String
    let value: String
}
