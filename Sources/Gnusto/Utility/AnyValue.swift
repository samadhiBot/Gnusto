import Foundation

/// A type-erased container for different Sendable types.
public struct AnyValue: Equatable, Sendable {
    private let _getValue: @Sendable () -> Any

    init<T: Sendable>(_ value: T) {
        self._getValue = { value }
    }

    func get<T>() -> T? {
        _getValue() as? T
    }

    public static func == (lhs: AnyValue, rhs: AnyValue) -> Bool {
        lhs.get() == rhs.get()
    }
}

extension AnyValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self._getValue = { value }
    }
}

extension AnyValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self._getValue = { value }
    }
}
