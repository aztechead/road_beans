import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct CommunityReviewContextSummaryProvider: Sendable {
    nonisolated init() {}

    func synthesizedSummary(for row: CommunityVisitRow) async -> String? {
        guard CommunityReviewContextSummary.facts(for: row).hasContext else { return nil }

        #if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
            return await foundationModelsSummary(for: row)
        case .unavailable:
            return nil
        }
        #else
        return nil
        #endif
    }

    #if canImport(FoundationModels)
    private func foundationModelsSummary(for row: CommunityVisitRow) async -> String? {
        let facts = CommunityReviewContextSummary.facts(for: row)
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: """
            Write one concise sentence describing what was reviewed in a Road Beans community coffee review.
            Use only the supplied drink/options and tags. Do not invent ingredients, service details, or place facts.
            Keep it under 18 words. Do not mention the reviewer, rating, or field labels.
            """
        )

        do {
            let response = try await session.respond(
                to: Prompt("""
                Drink/options: \(facts.options.joined(separator: ", "))
                Tags: \(facts.tags.joined(separator: ", "))
                """),
                generating: GeneratedCommunityReviewContext.self
            )
            let sentence = response.content.sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            return CommunityReviewContextSummary.isUsable(sentence) ? sentence : nil
        } catch {
            return nil
        }
    }
    #endif
}

enum CommunityReviewContextSummary {
    struct Facts: Sendable, Equatable {
        let options: [String]
        let tags: [String]

        var hasContext: Bool {
            !options.isEmpty || !tags.isEmpty
        }
    }

    static func facts(for row: CommunityVisitRow) -> Facts {
        Facts(
            options: parsedTokens(from: row.drinkSummary),
            tags: parsedTokens(from: row.tagSummary)
        )
    }

    static func fallbackSummary(for row: CommunityVisitRow) -> String? {
        let facts = facts(for: row)
        guard facts.hasContext else { return nil }

        switch (facts.options.isEmpty, facts.tags.isEmpty) {
        case (false, false):
            return "Reviewed \(joined(facts.options)) with \(joined(facts.tags)) notes."
        case (false, true):
            return "Reviewed \(joined(facts.options))."
        case (true, false):
            return "Tagged as \(joined(facts.tags))."
        case (true, true):
            return nil
        }
    }

    static func isUsable(_ sentence: String) -> Bool {
        guard !sentence.isEmpty else { return false }
        guard sentence.count <= 140 else { return false }

        let lower = sentence.lowercased()
        let bannedTerms = ["drink/options", "tags:", "field", "reviewer", "rating"]
        guard !bannedTerms.contains(where: { lower.contains($0) }) else { return false }

        let words = sentence.split { $0.isWhitespace }
        return (4...22).contains(words.count)
    }

    private static func parsedTokens(from summary: String) -> [String] {
        summary
            .split(separator: ",")
            .map { token in
                token
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "  ", with: " ")
            }
            .filter { !$0.isEmpty }
    }

    private static func joined(_ values: [String]) -> String {
        switch values.count {
        case 0:
            ""
        case 1:
            values[0]
        case 2:
            values.joined(separator: " and ")
        default:
            values.dropLast().joined(separator: ", ") + ", and " + (values.last ?? "")
        }
    }
}

#if canImport(FoundationModels)
@Generable
private struct GeneratedCommunityReviewContext {
    let sentence: String
}
#endif
