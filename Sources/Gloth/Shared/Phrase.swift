import Foundation

struct Phrase: Comparable, CustomStringConvertible, Hashable {
    let elements: [Word]

    init(_ elements: [Word]) {
        self.elements = elements
    }

    var description: String {
        elements.map { $0.token }.joined(separator: " ")
    }

    var toJSON: String {
        let tokens = tokens.map { "\"\($0)\"" }
            .joined(separator: ", ")
        let labels = labels.map { "\"\($0)\"" }
            .joined(separator: ", ")
        return """
            {
                    "tokens": [\(tokens)],
                    "labels": [\(labels)]
                }
            """
    }

    var labels: [String] {
        elements.map { $0.label }
    }

    var tokens: [String] {
        elements.map { $0.token }
    }

    static func < (lhs: Phrase, rhs: Phrase) -> Bool {
        lhs.description < rhs.description
    }
}
