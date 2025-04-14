import Foundation

extension String {
    /// Returns the string with the first character capitalized.
    ///
    /// - Returns: The string with the first character capitalized.
    var capped: String {
        if let first {
            first.uppercased() + dropFirst()
        } else {
            self
        }
    }
}
