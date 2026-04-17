import Foundation

/// Pure-function fuzzy filter for the command palette.
///
/// Behaviour:
/// - Empty query returns the input untouched.
/// - A match requires all query characters (case-folded) to appear in order
///   within the candidate title.
/// - Scoring favours:
///   - prefix matches,
///   - contiguous matches,
///   - shorter candidates.
public struct CommandPaletteFuzzyFilter: Sendable {
    public init() {}

    public func filter(items: [CommandPaletteItem], query: String) -> [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else {
            return items
        }

        let queryLower = trimmed.lowercased()

        var scored: [(item: CommandPaletteItem, score: Double, index: Int)] = []
        scored.reserveCapacity(items.count)

        for (idx, item) in items.enumerated() {
            if let score = Self.score(query: queryLower, in: item.title) {
                scored.append((item, score, idx))
            }
        }

        scored.sort { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            return lhs.index < rhs.index
        }

        return scored.map(\.item)
    }

    /// Returns a match score if `query` fuzzy-matches `title`, else `nil`.
    /// Higher = better. Components:
    ///   - prefix match at index 0                 -> +10
    ///   - longest contiguous run of matches        -> +3 per char
    ///   - match density (queryLen / titleLen)      -> +2 * ratio
    ///   - separator penalty (-1 per `-`/`_`/` `/`.`) to prefer continuous-alpha candidates
    private static func score(query: String, in title: String) -> Double? {
        let titleLower = title.lowercased()
        let queryChars = Array(query)
        let titleChars = Array(titleLower)
        guard queryChars.isEmpty == false else { return 1.0 }

        var ti = 0
        var qi = 0
        var currentRun = 0
        var maxRun = 0
        var firstMatchIndex: Int? = nil
        var previousMatchIndex: Int? = nil

        while ti < titleChars.count && qi < queryChars.count {
            if titleChars[ti] == queryChars[qi] {
                if firstMatchIndex == nil { firstMatchIndex = ti }
                if let prev = previousMatchIndex, prev == ti - 1 {
                    currentRun += 1
                } else {
                    currentRun = 1
                }
                maxRun = max(maxRun, currentRun)
                previousMatchIndex = ti
                qi += 1
                ti += 1
            } else {
                ti += 1
            }
        }

        if qi < queryChars.count { return nil }

        let titleLen = Double(max(titleChars.count, 1))
        let queryLen = Double(queryChars.count)

        var score = 2.0 * (queryLen / titleLen)
        if firstMatchIndex == 0 {
            score += 10.0
        }
        score += 3.0 * Double(maxRun)

        // Penalty for candidates where matched characters are split across
        // separators (hyphen/underscore/space). Continuous-alpha candidates
        // outrank fragmented ones even when both have the same `maxRun`.
        let separators: Set<Character> = ["-", "_", " ", "."]
        let separatorCount = titleChars.filter { separators.contains($0) }.count
        score -= 1.0 * Double(separatorCount)

        return score
    }
}
