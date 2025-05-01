import Foundation

extension Array where Element == Item {
    /// Returns a grammatically correct string listing the elements,
    /// sorted alphabetically, with appropriate indefinite articles prepended.
    ///
    /// Example: `["pear", "apple", "banana"]` becomes `"an apple, a banana and a pear"`.
    /// Returns "nothing" for an empty array.
    var listWithIndefiniteArticles: String {
        switch count {
        case 0:
            return "nothing"
        case 1:
            return self[0].withIndefiniteArticle
        default:
            var sortedItemsWithArticles = sorted()
                .map(\.withIndefiniteArticle)
            let lastItem = sortedItemsWithArticles.removeLast()
            return "\(sortedItemsWithArticles.joined(separator: ", ")) and \(lastItem)"
        }
    }
}
