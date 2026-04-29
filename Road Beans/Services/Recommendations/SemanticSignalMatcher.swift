import Foundation
@preconcurrency import NaturalLanguage

protocol SemanticSignalMatcher: Sendable {
    func tokens(in text: String) -> [String]
    func match(keyword: String, in tokens: [String]) -> SemanticMatchResult
}

struct SemanticMatchResult: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        case none
        case exact
        case related(score: Double)
    }
    let kind: Kind

    static let none = SemanticMatchResult(kind: .none)
    static let exact = SemanticMatchResult(kind: .exact)
    static func related(_ score: Double) -> SemanticMatchResult { .init(kind: .related(score: score)) }

    var matched: Bool {
        switch kind {
        case .none: false
        case .exact, .related: true
        }
    }
}

final class NLEmbeddingSemanticSignalMatcher: SemanticSignalMatcher, @unchecked Sendable {
    static let similarityThreshold: Double = 0.62

    private let embedding: NLEmbedding?

    init(language: NLLanguage = .english) {
        self.embedding = NLEmbedding.wordEmbedding(for: language)
    }

    func tokens(in text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var out: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let token = text[range]
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
            if token.count >= 3 { out.append(token) }
            return true
        }
        return out
    }

    func match(keyword: String, in tokens: [String]) -> SemanticMatchResult {
        let needle = keyword
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        guard !needle.isEmpty, !tokens.isEmpty else { return .none }
        if tokens.contains(needle) { return .exact }

        guard let embedding else { return .none }
        var bestSimilarity: Double = 0
        for token in tokens where token != needle {
            let distance = embedding.distance(between: needle, and: token, distanceType: .cosine)
            guard distance.isFinite, distance > 0 else { continue }
            let similarity = max(0, 1 - distance / 2)
            if similarity > bestSimilarity { bestSimilarity = similarity }
        }
        return bestSimilarity >= Self.similarityThreshold ? .related(bestSimilarity) : .none
    }
}

struct LiteralSemanticSignalMatcher: SemanticSignalMatcher {
    func tokens(in text: String) -> [String] {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count >= 3 }
    }

    func match(keyword: String, in tokens: [String]) -> SemanticMatchResult {
        let needle = keyword
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        guard !needle.isEmpty else { return .none }
        return tokens.contains(needle) ? .exact : .none
    }
}
