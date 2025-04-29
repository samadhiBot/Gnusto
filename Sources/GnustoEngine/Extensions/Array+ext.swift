import Foundation

extension Array where Element == String {
    /// Returns a grammatically correct string listing the elements,
    /// sorted alphabetically, with appropriate indefinite articles prepended.
    ///
    /// Example: `["pear", "apple", "banana"]` becomes `"an apple, a banana and a pear"`.
    /// Returns "nothing" for an empty array.
    var listWithIndefiniteArticles: String {
        guard !self.isEmpty else {
            return "nothing"
        }

        let sortedItemsWithArticles = self.sorted().map { $0.withIndefiniteArticle }

        guard sortedItemsWithArticles.count > 1 else {
            return sortedItemsWithArticles.first ?? "" // Should always have one if count is 1
        }

        let allButLast = sortedItemsWithArticles.dropLast()
        let lastItem = sortedItemsWithArticles.last! // Safe due to guard above

        return "\(allButLast.joined(separator: ", ")) and \(lastItem)"
    }
} 