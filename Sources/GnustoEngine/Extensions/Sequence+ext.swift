import Foundation

extension Sequence {
    /// Asynchronously transforms each element of the sequence using the given closure,
    /// filtering out any `nil` results.
    ///
    /// This is the async equivalent of the standard library's `compactMap` method.
    /// The transformation closure is called sequentially for each element in the sequence.
    ///
    /// - Parameter transform: An async throwing closure that transforms each element
    ///   of the sequence into an optional value of type `T`.
    /// - Returns: An array containing the non-`nil` results of calling `transform`
    ///   on each element of the sequence.
    /// - Throws: Any error thrown by the `transform` closure.
    public func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async throws -> [T] {
        var results: [T] = []
        for element in self {
            if let value = try await transform(element) {
                results.append(value)
            }
        }
        return results
    }

    /// Asynchronously filters the sequence, returning an array containing only
    /// the elements that satisfy the given predicate.
    ///
    /// This is the async equivalent of the standard library's `filter` method.
    /// The predicate closure is called sequentially for each element in the sequence.
    ///
    /// - Parameter isIncluded: An async throwing closure that takes an element
    ///   and returns `true` if the element should be included in the result.
    /// - Returns: An array containing the elements for which `isIncluded` returned `true`.
    /// - Throws: Any error thrown by the `isIncluded` closure.
    public func asyncFilter(
        _ isIncluded: (Element) async throws -> Bool
    ) async throws -> [Element] {
        var results: [Element] = []
        for element in self {
            if try await isIncluded(element) {
                results.append(element)
            }
        }
        return results
    }

    /// Asynchronously transforms each element of the sequence using the given closure.
    ///
    /// This is the async equivalent of the standard library's `map` method.
    /// The transformation closure is called sequentially for each element in the sequence.
    ///
    /// - Parameter transform: An async throwing closure that transforms each element
    ///   of the sequence into a value of type `T`.
    /// - Returns: An array containing the results of calling `transform` on each
    ///   element of the sequence.
    /// - Throws: Any error thrown by the `transform` closure.
    public func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var results = [T]()
        for element in self {
            try await results.append(transform(element))
        }
        return results
    }

    /// Asynchronously checks whether the sequence contains an element that satisfies
    /// the given predicate.
    ///
    /// This is the async equivalent of the standard library's `contains(where:)` method.
    /// The predicate is evaluated sequentially for each element until one returns `true`
    /// or the sequence is exhausted.
    ///
    /// - Parameter predicate: An async throwing closure that takes an element
    ///   and returns `true` if the element matches the desired criteria.
    /// - Returns: `true` if the sequence contains an element that satisfies the predicate;
    ///   otherwise, `false`.
    /// - Throws: Any error thrown by the `predicate` closure.
    public func contains(
        where predicate: (Element) async throws -> Bool
    ) async throws -> Bool {
        for element in self {
            if try await predicate(element) {
                return true
            }
        }
        return false
    }
}
