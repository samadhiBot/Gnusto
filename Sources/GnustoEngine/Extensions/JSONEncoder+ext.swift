import Foundation

extension JSONEncoder {
    /// Creates a JSONEncoder with sorted keys enabled.
    ///
    /// - Parameter formatting: Additional output formatting options to apply.
    ///   The `.sortedKeys` option will be automatically added to whatever formatting is provided.
    /// - Returns: A configured JSONEncoder instance with sorted keys and any additional formatting options.
    public static func sorted(
        _ formatting: JSONEncoder.OutputFormatting = []
    ) -> JSONEncoder {
        let encoder = JSONEncoder()
        var formatting = formatting
        formatting.insert(.sortedKeys)
        encoder.outputFormatting = formatting
        return encoder
    }
}
