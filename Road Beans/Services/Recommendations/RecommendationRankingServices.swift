import Foundation

enum RecommendationRanking {
    static let highlyRatedThreshold: Double = 4.0

    static func isHighlyRatedLocal(_ candidate: RecommendationCandidate) -> Bool {
        candidate.source == .local
            && candidate.localVisitCount > 0
            && (candidate.localAverageRating ?? 0) >= highlyRatedThreshold
    }

    static func personalHistoryReason(for candidate: RecommendationCandidate) -> String? {
        guard let rating = candidate.localAverageRating, candidate.localVisitCount > 0 else { return nil }
        return "You rated this stop \(String(format: "%.1f", rating)) beans before."
    }

    static func formattedDistance(_ meters: Double) -> String {
        let miles = meters / 1_609.344
        return String(format: "%.2f mi", miles)
    }

    static func bubbleHighlyRatedLocal(_ recs: [PlaceRecommendation], lookup: [String: EnrichedRecommendationCandidate]) -> [PlaceRecommendation] {
        var pinned: [PlaceRecommendation] = []
        var rest: [PlaceRecommendation] = []
        for rec in recs {
            if let enriched = lookup[rec.id], isHighlyRatedLocal(enriched.candidate) {
                pinned.append(rec)
            } else {
                rest.append(rec)
            }
        }
        let byScore: (PlaceRecommendation, PlaceRecommendation) -> Bool = { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            let lhsDistance = lhs.distanceMeters ?? .greatestFiniteMagnitude
            let rhsDistance = rhs.distanceMeters ?? .greatestFiniteMagnitude
            return lhsDistance < rhsDistance
        }
        pinned.sort(by: byScore)
        rest.sort(by: byScore)
        return pinned + rest
    }
}

struct HeuristicRecommendationRankingService: RecommendationRankingService {
    var availabilityMessage: String? { nil }

    private let matcher: any SemanticSignalMatcher

    init(matcher: any SemanticSignalMatcher = NLEmbeddingSemanticSignalMatcher()) {
        self.matcher = matcher
    }

    func rank(
        profile: RecommendationTasteProfile,
        candidates: [EnrichedRecommendationCandidate]
    ) async throws -> [PlaceRecommendation] {
        let lookup = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        let ranked = candidates
            .map { recommendation(for: $0, profile: profile) }
            .sorted {
                if $0.score == $1.score {
                    ($0.distanceMeters ?? .greatestFiniteMagnitude) < ($1.distanceMeters ?? .greatestFiniteMagnitude)
                } else {
                    $0.score > $1.score
                }
            }
        return Array(RecommendationRanking.bubbleHighlyRatedLocal(ranked, lookup: lookup).prefix(6))
    }

    private func recommendation(
        for enriched: EnrichedRecommendationCandidate,
        profile: RecommendationTasteProfile
    ) -> PlaceRecommendation {
        let candidate = enriched.candidate
        let signalResult = matchedSignals(candidate: candidate, profile: profile, publicSignals: enriched.publicSignals)
        let matchedSignals = signalResult.signals
        var score = 52

        if candidate.kind == .coffeeShop { score += 14 }
        if profile.preferredPlaceKinds.prefix(3).contains(candidate.kind) { score += 12 }
        if candidate.source == .local { score += 8 }
        if let rating = candidate.localAverageRating {
            score += Int((rating - 3) * 8)
        }
        score += min(12, signalResult.exactCount * 4 + signalResult.relatedCount * 2)
        score -= min(20, signalResult.dislikedExactCount * 6 + signalResult.dislikedRelatedCount * 3)
        if let distance = candidate.distanceMeters {
            score += max(0, 10 - Int(distance / 800))
        }
        score = min(96, max(20, score))

        return PlaceRecommendation(
            id: candidate.id,
            source: candidate.source,
            placeID: candidate.placeID,
            mapKitIdentifier: candidate.mapKitIdentifier,
            placeName: candidate.name,
            kind: candidate.kind,
            address: candidate.address,
            coordinate: candidate.coordinate,
            distanceMeters: candidate.distanceMeters,
            score: score,
            confidence: confidence(for: score),
            reasons: reasons(candidate: candidate, profile: profile, matchedSignals: matchedSignals),
            cautions: cautions(candidate: candidate, dislikedHits: signalResult.dislikedSignals),
            matchedSignals: matchedSignals,
            attributions: enriched.attributions
        )
    }

    private struct MatchedSignalResult {
        let signals: [String]
        let exactCount: Int
        let relatedCount: Int
        let dislikedSignals: [String]
        let dislikedExactCount: Int
        let dislikedRelatedCount: Int
    }

    private func matchedSignals(
        candidate: RecommendationCandidate,
        profile: RecommendationTasteProfile,
        publicSignals: [String]
    ) -> MatchedSignalResult {
        var signals: [String] = []
        var exactCount = 0
        var relatedCount = 0
        var dislikedSignals: [String] = []
        var dislikedExactCount = 0
        var dislikedRelatedCount = 0
        let haystack = ([candidate.name, candidate.address].compactMap { $0 } + publicSignals)
            .joined(separator: " ")
        let tokens = matcher.tokens(in: haystack)

        for keyword in profile.preferredTags + profile.preferredDrinks {
            let result = matcher.match(keyword: keyword.value, in: tokens)
            switch result.kind {
            case .exact:
                signals.append(keyword.value)
                exactCount += 1
            case .related:
                signals.append("\(keyword.value) (related)")
                relatedCount += 1
            case .none:
                break
            }
        }

        for keyword in profile.dislikedTags + profile.dislikedDrinks {
            let result = matcher.match(keyword: keyword.value, in: tokens)
            switch result.kind {
            case .exact:
                dislikedSignals.append(keyword.value)
                dislikedExactCount += 1
            case .related:
                dislikedSignals.append("\(keyword.value) (related)")
                dislikedRelatedCount += 1
            case .none:
                break
            }
        }

        if profile.preferredPlaceKinds.contains(candidate.kind) {
            signals.append(candidate.kind.displayName)
        }

        let unique = Array(NSOrderedSet(array: signals)) as? [String] ?? signals
        let uniqueDisliked = Array(NSOrderedSet(array: dislikedSignals)) as? [String] ?? dislikedSignals
        return MatchedSignalResult(
            signals: unique,
            exactCount: exactCount,
            relatedCount: relatedCount,
            dislikedSignals: uniqueDisliked,
            dislikedExactCount: dislikedExactCount,
            dislikedRelatedCount: dislikedRelatedCount
        )
    }

    private func reasons(
        candidate: RecommendationCandidate,
        profile: RecommendationTasteProfile,
        matchedSignals: [String]
    ) -> [String] {
        var reasons: [String] = []
        if RecommendationRanking.isHighlyRatedLocal(candidate),
           let personal = RecommendationRanking.personalHistoryReason(for: candidate) {
            reasons.append(personal)
        }
        if !matchedSignals.isEmpty {
            reasons.append("Matches your history around \(matchedSignals.prefix(3).joined(separator: ", ")).")
        }
        if !RecommendationRanking.isHighlyRatedLocal(candidate),
           let rating = candidate.localAverageRating, candidate.localVisitCount > 0 {
            reasons.append("You have rated this stop around \(String(format: "%.1f", rating)) beans before.")
        } else if reasons.count < 2 {
            if candidate.kind == .coffeeShop {
                reasons.append("It is a nearby coffee stop within your 5-mile search radius.")
            } else {
                reasons.append("It fits your road-stop pattern and is close enough for a quick detour.")
            }
        }
        if reasons.count < 2, !profile.summary.isEmpty {
            reasons.append("Built from your local Road Beans taste profile.")
        }
        return Array(reasons.prefix(3))
    }

    private func cautions(candidate: RecommendationCandidate, dislikedHits: [String]) -> [String] {
        var out: [String] = []
        if !dislikedHits.isEmpty {
            out.append("Mentions things you have rated low: \(dislikedHits.prefix(3).joined(separator: ", ")).")
        }
        if candidate.source != .local {
            out.append("Not saved in Road Beans yet, so this is based on Apple Maps place data.")
        } else {
            out.append("Based on your saved history, not live public reviews.")
        }
        return Array(out.prefix(2))
    }

    private func confidence(for score: Int) -> RecommendationConfidence {
        if score >= 78 { return .high }
        if score >= 62 { return .medium }
        return .low
    }
}

#if canImport(FoundationModels)
import FoundationModels

struct FoundationModelsRecommendationRankingService: RecommendationRankingService {
    private let fallback: HeuristicRecommendationRankingService
    private let matcher: any SemanticSignalMatcher

    init(matcher: any SemanticSignalMatcher = NLEmbeddingSemanticSignalMatcher()) {
        self.matcher = matcher
        self.fallback = HeuristicRecommendationRankingService(matcher: matcher)
    }

    var availabilityMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            nil
        case .unavailable(let reason):
            "Apple Intelligence is unavailable: \(reason)"
        }
    }

    func rank(
        profile: RecommendationTasteProfile,
        candidates: [EnrichedRecommendationCandidate]
    ) async throws -> [PlaceRecommendation] {
        switch SystemLanguageModel.default.availability {
        case .available:
            do {
                return try await modelRank(profile: profile, candidates: Array(candidates.prefix(12)))
            } catch {
                return try await fallback.rank(profile: profile, candidates: candidates)
            }
        case .unavailable:
            return try await fallback.rank(profile: profile, candidates: candidates)
        }
    }

    private func modelRank(
        profile: RecommendationTasteProfile,
        candidates: [EnrichedRecommendationCandidate]
    ) async throws -> [PlaceRecommendation] {
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: """
            You write short, friendly explanations for why a nearby place fits a coffee-and-road-stop user.
            Rank candidates using only supplied candidate data and the local taste profile. Prefer coffee
            shops and useful road stops the user already favors.

            Score format — STRICT:
            - score is an integer 0-100 representing match quality (think probability × 100).
            - 90+ = strong match, 70-89 = good, 50-69 = okay, below 30 = weak.
            - score is NEVER a rank index (do not output 1, 2, 3 as positions).
            - Distinct candidates should usually have distinct scores spread across the scale.

            Reason format — STRICT:
            - Each reason is one complete sentence of 8 to 20 words, ending with a period.
            - Write in second person ("you", "your taste") or describe the place directly.
            - Reference concrete attributes: kind, name, matched tags or drinks.
            - Do not mention numeric distance or proximity.
            - Never output fragments like "Has website", "Has phone", "Distance", or single nouns.
            - Never output "key: value" pairs (e.g. "localRating: none", "distanceMeters: 600").
            - Never echo field labels: dislikedDrinks, preferredTags, localRating, distanceMeters,
              publicSignals, exactKeywordMatches, semanticallyRelatedKeywords.
            - Never use the literal word "none".
            - Each of the 1-3 reasons must be distinct.

            matchedSignals format:
            - Verbatim terms from the candidate's listed signals or the user's preferred tags/drinks.
            - Never field labels.

            Be honest. Do not invent public reviews or hours.
            """
        )
        let response = try await session.respond(
            to: Prompt(prompt(profile: profile, candidates: candidates)),
            generating: GeneratedRecommendationList.self
        )
        let generated = response.content.recommendations
        let byID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        let preferredKinds = Set(profile.preferredPlaceKinds)

        let maxScore = generated.map(\.score).max() ?? 0
        if maxScore <= 10 {
            return try await fallback.rank(profile: profile, candidates: candidates)
        }

        let modelRecs = generated.compactMap { item -> PlaceRecommendation? in
            guard let enriched = byID[item.id] else { return nil }
            let candidate = enriched.candidate
            let whitelist = signalWhitelist(for: enriched, profile: profile)
            let cleanedSignals = item.matchedSignals
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { signal in
                    guard !signal.isEmpty, !Self.bannedTerms.contains(signal.lowercased()) else { return false }
                    return whitelist.contains(signal.lowercased())
                }
            let cleanedReasons = item.reasons
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter(Self.isCleanNarrative)
            var dedupedReasons = Array(NSOrderedSet(array: cleanedReasons)) as? [String] ?? cleanedReasons
            if dedupedReasons.isEmpty {
                dedupedReasons = fallbackReasons(for: enriched, signals: cleanedSignals)
            }
            if RecommendationRanking.isHighlyRatedLocal(candidate),
               let personal = RecommendationRanking.personalHistoryReason(for: candidate) {
                dedupedReasons.removeAll { $0 == personal }
                dedupedReasons.insert(personal, at: 0)
            }
            let cleanedCautions = item.cautions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter(Self.isCleanNarrative)

            let rawScore = max(25, min(100, item.score))
            let cappedScore = preferredKinds.isEmpty || preferredKinds.contains(candidate.kind) ? rawScore : min(rawScore, 60)

            return PlaceRecommendation(
                id: candidate.id,
                source: candidate.source,
                placeID: candidate.placeID,
                mapKitIdentifier: candidate.mapKitIdentifier,
                placeName: candidate.name,
                kind: candidate.kind,
                address: candidate.address,
                coordinate: candidate.coordinate,
                distanceMeters: candidate.distanceMeters,
                score: cappedScore,
                confidence: confidence(for: cappedScore),
                reasons: Array(dedupedReasons.prefix(3)),
                cautions: Array(cleanedCautions.prefix(2)),
                matchedSignals: Array(cleanedSignals.prefix(5)),
                attributions: enriched.attributions
            )
        }
        return RecommendationRanking.bubbleHighlyRatedLocal(modelRecs, lookup: byID)
    }

    private static let bannedTerms: Set<String> = [
        "dislikeddrinks", "dislikedtags", "dislikedkeywordhits",
        "preferredtags", "preferreddrinks", "preferredplacekinds",
        "exactkeywordmatches", "semanticallyrelatedkeywords",
        "localrating", "localvisits", "distancemeters", "mapkitidentifier",
        "publicsignals", "websiteurl", "phonenumber"
    ]

    private static let promptEchoPattern = #/^\s*[A-Za-z]+\s*:\s*\S/#

    private static func isCleanNarrative(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let lower = text.lowercased()
        if lower == "none" { return false }
        if bannedTerms.contains(where: { lower.contains($0) }) { return false }
        if text.firstMatch(of: promptEchoPattern) != nil { return false }
        let words = text.split { $0.isWhitespace }
        if words.count < 5 { return false }
        let endsCleanly = text.last.map { ".!?".contains($0) } ?? false
        return endsCleanly
    }

    private func fallbackReasons(for enriched: EnrichedRecommendationCandidate, signals: [String]) -> [String] {
        let candidate = enriched.candidate
        var out: [String] = []
        if !signals.isEmpty {
            out.append("Matches your taste around \(signals.prefix(3).joined(separator: ", ")).")
        }
        if let rating = candidate.localAverageRating, candidate.localVisitCount > 0 {
            out.append("You rated this stop around \(String(format: "%.1f", rating)) beans before.")
        } else if candidate.kind == .coffeeShop {
            out.append("Coffee stop within your 5-mile search radius.")
        } else {
            out.append("\(candidate.kind.displayName) close enough for a quick detour.")
        }
        return Array(out.prefix(3))
    }

    private func signalWhitelist(for enriched: EnrichedRecommendationCandidate, profile: RecommendationTasteProfile) -> Set<String> {
        var allowed: Set<String> = []
        let add: (String) -> Void = { value in
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            allowed.insert(trimmed.lowercased())
        }
        for signal in enriched.publicSignals { add(signal) }
        for keyword in profile.preferredTags + profile.preferredDrinks { add(keyword.value) }
        add(enriched.candidate.kind.displayName)
        return allowed
    }

    private func prompt(profile: RecommendationTasteProfile, candidates: [EnrichedRecommendationCandidate]) -> String {
        let candidateLines = candidates.map { enriched in
            let candidate = enriched.candidate
            let haystack = ([candidate.name, candidate.address].compactMap { $0 } + enriched.publicSignals).joined(separator: " ")
            let tokens = matcher.tokens(in: haystack)
            var exact: [String] = []
            var related: [String] = []
            var dislikedHits: [String] = []
            for keyword in profile.preferredTags + profile.preferredDrinks {
                switch matcher.match(keyword: keyword.value, in: tokens).kind {
                case .exact: exact.append(keyword.value)
                case .related: related.append(keyword.value)
                case .none: break
                }
            }
            for keyword in profile.dislikedTags + profile.dislikedDrinks {
                if matcher.match(keyword: keyword.value, in: tokens).matched {
                    dislikedHits.append(keyword.value)
                }
            }
            return """
            id: \(candidate.id)
            name: \(candidate.name)
            kind: \(candidate.kind.displayName)
            localRating: \(candidate.localAverageRating.map { String(format: "%.1f", $0) } ?? "none")
            localVisits: \(candidate.localVisitCount)
            signals: \(enriched.publicSignals.joined(separator: ", "))
            exactKeywordMatches: \(exact.joined(separator: ", "))
            semanticallyRelatedKeywords: \(related.joined(separator: ", "))
            dislikedKeywordHits: \(dislikedHits.joined(separator: ", "))
            """
        }.joined(separator: "\n---\n")

        return """
        Local taste profile (positive signals to seek):
        tags: \(profile.preferredTags.map(\.value).joined(separator: ", "))
        drinks: \(profile.preferredDrinks.map(\.value).joined(separator: ", "))
        placeKinds: \(profile.preferredPlaceKinds.map(\.displayName).joined(separator: ", "))

        Negative signals (avoid generic dislikes; only flag a candidate when explicitly hit, not by category):
        dislikedTags: \(profile.dislikedTags.map(\.value).joined(separator: ", "))
        dislikedDrinks: \(profile.dislikedDrinks.map(\.value).joined(separator: ", "))

        Important: a low-rated drink at one place does not mean the same drink is bad everywhere.
        Only downrank a candidate when its own data hits a disliked signal (see dislikedKeywordHits per candidate).

        Candidates:
        \(candidateLines)
        """
    }

    private func confidence(for score: Int) -> RecommendationConfidence {
        if score >= 78 { return .high }
        if score >= 62 { return .medium }
        return .low
    }
}

@Generable
private struct GeneratedRecommendationList {
    @Guide(.maximumCount(6))
    let recommendations: [GeneratedRecommendation]
}

@Generable
private struct GeneratedRecommendation {
    let id: String

    @Guide(.range(1...100))
    let score: Int

    @Guide(.maximumCount(3))
    let reasons: [String]

    @Guide(.maximumCount(2))
    let cautions: [String]

    @Guide(.maximumCount(5))
    let matchedSignals: [String]
}
#endif
