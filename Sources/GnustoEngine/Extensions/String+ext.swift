import Foundation

extension String {
    /// The string with the first letter capitalized.
    var capitalizedFirst: String {
        guard let firstCharacter = first else {
            return self
        }
        return String(firstCharacter).uppercased() + dropFirst()
    }
}
