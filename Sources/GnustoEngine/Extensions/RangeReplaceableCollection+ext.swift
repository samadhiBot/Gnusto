import Foundation

extension RangeReplaceableCollection {
    /// Appends one or more optional elements to the end of the collection.
    ///
    /// This convenience method provides a safe way to append optional values to a collection.
    /// If an element is `nil`, the method performs no operation and the collection remains unchanged.
    /// If an element contains a value, it is unwrapped and appended to the collection.
    ///
    /// This is particularly useful when working with optional values that may or may not need
    /// to be added to a collection, eliminating the need for explicit nil-checking at the call site.
    ///
    /// ```swift
    /// var numbers: [Int] = [1, 2, 3]
    /// let optionalFour: Int? = 4
    /// let optionalNil: Int? = nil
    ///
    /// numbers.append(optionalFour)  // numbers is now [1, 2, 3, 4]
    /// numbers.append(optionalNil)   // numbers remains [1, 2, 3, 4]
    /// ```
    ///
    /// - Parameter newElements: Optional elements to append to the collection.
    public mutating func append(_ newElements: Element?...) {
        for element in newElements {
            guard let element else { continue }
            self.append(element)
        }
    }
}
