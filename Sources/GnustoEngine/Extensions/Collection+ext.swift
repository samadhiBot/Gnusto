import Foundation

extension Collection {
    /// Returns a sorted array of the collection's elements using an async comparison predicate.
    ///
    /// This method performs an asynchronous insertion sort, allowing for comparison operations
    /// that require async/await (such as network requests or database queries). The sorting
    /// is stable, meaning that elements that compare as equal retain their relative order.
    ///
    /// ```swift
    /// let users = [user1, user2, user3]
    /// let sortedUsers = await users.asyncSorted { first, second in
    ///     let firstScore = await fetchUserScore(first)
    ///     let secondScore = await fetchUserScore(second)
    ///     return firstScore < secondScore
    /// }
    /// ```
    ///
    /// - Parameter areInIncreasingOrder: An async predicate that returns `true` if the first
    ///   element should be ordered before the second element; otherwise, `false`.
    /// - Returns: A new array containing the collection's elements sorted according to the
    ///   given predicate.
    /// - Complexity: O(n²) where n is the length of the collection, due to the insertion sort
    ///   algorithm used. Each comparison is performed asynchronously.
    func asyncSorted(
        by areInIncreasingOrder: @escaping (Element, Element) async -> Bool
    ) async -> [Element] {
        var result = Array(self)
        guard count > 1 else { return result }
        for i in 1..<result.count {
            var j = i
            while j > 0 {
                let shouldSwap = await areInIncreasingOrder(result[j], result[j - 1])
                if shouldSwap {
                    result.swapAt(j, j - 1)
                    j -= 1
                } else {
                    break
                }
            }
        }
        return result
    }

    /// Returns `true` if the collection is not empty.
    ///
    /// This is a convenience property that provides a more readable alternative
    /// to `!isEmpty` when checking for the presence of elements in a collection.
    ///
    /// ```swift
    /// let numbers = [1, 2, 3]
    /// if numbers.isNotEmpty {
    ///     print("We have numbers!")
    /// }
    /// ```
    ///
    /// - Complexity: O(1)
    public var isNotEmpty: Bool {
        !isEmpty
    }
}

extension Collection where Element: Comparable {
    /// Returns a sorted array of the collection's elements using their natural ordering.
    ///
    /// This is a convenience method for collections of `Comparable` elements that provides
    /// async sorting using the default `<` comparison operator. Elements are sorted in
    /// ascending order.
    ///
    /// ```swift
    /// let numbers = [3, 1, 4, 1, 5]
    /// let sortedNumbers = await numbers.asyncSorted()
    /// // Result: [1, 1, 3, 4, 5]
    /// ```
    ///
    /// - Returns: A new array containing the collection's elements sorted in ascending order.
    /// - Complexity: O(n²) where n is the length of the collection, due to the insertion sort
    ///   algorithm used.
    func asyncSorted() async -> [Element] {
        await asyncSorted(by: { $0 < $1 })
    }
}

extension Collection where Element: Hashable {
    /// Returns `true` if this collection has any elements in common with the other collection.
    ///
    /// This method efficiently determines whether two collections share any common elements
    /// by converting the `other` collection to a `Set` for O(1) lookup performance.
    /// The method stops as soon as the first common element is found.
    ///
    /// ```swift
    /// let fruits = ["apple", "banana", "orange"]
    /// let citrus = ["lemon", "orange", "grapefruit"]
    ///
    /// if fruits.intersects(citrus) {
    ///     print("Some fruits are citrus!") // Prints this
    /// }
    /// ```
    ///
    /// - Parameter other: The collection to check for intersection with this collection.
    /// - Returns: `true` if at least one element exists in both collections, `false` otherwise.
    /// - Complexity: O(m + n) where m is the size of `other` (to create the Set) and
    ///   n is the size of this collection in the worst case.
    public func intersects<C: Collection>(_ other: C) -> Bool where C.Element == Element {
        self.contains(where: Set(other).contains)
    }
}
