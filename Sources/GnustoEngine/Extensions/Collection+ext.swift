import Foundation

extension Collection {
    /// Returns `true` if the collection is not empty.
    public var isNotEmpty: Bool {
        !isEmpty
    }
}

extension Collection where Element: Hashable {
    /// Returns `true` if this collection has any elements in common with the other collection.
    ///
    /// - Parameter other: The collection to check for intersection.
    /// - Returns: `true` if at least one element exists in both collections, `false` otherwise.
    public func intersects<C: Collection>(_ other: C) -> Bool where C.Element == Element {
        self.contains(where: Set(other).contains)
    }
}
