import Foundation

extension Object {
    /// A unique identifier for objects in the game world.
    public struct ID: Codable, Hashable, ExpressibleByStringLiteral, Sendable {
        let rawValue: String

        public init(stringLiteral value: StringLiteralType) {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            assert(!trimmedValue.isEmpty, "Object.ID cannot be empty.")
            rawValue = trimmedValue
        }

        public init(_ value: String) {
            self = Object.ID(stringLiteral: value)
        }
    }
}

extension Object.ID: Comparable {
    public static func < (lhs: Object.ID, rhs: Object.ID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
