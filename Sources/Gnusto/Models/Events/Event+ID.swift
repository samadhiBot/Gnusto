import Foundation

extension Event {
    /// A unique identifier for scheduled events in the game world.
    public struct ID: Hashable, ExpressibleByStringLiteral, Sendable {
        let rawValue: String

        public init(stringLiteral value: StringLiteralType) {
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            assert(!trimmedValue.isEmpty, "Event.ID cannot be empty.")
            rawValue = trimmedValue
        }

        public init(_ value: String) {
            self = Event.ID(stringLiteral: value)
        }
    }
}
