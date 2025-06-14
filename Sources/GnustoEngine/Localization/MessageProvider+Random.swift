/// Extension to support random message selection from multiline strings.
///
/// This extension provides utilities for handling messages that contain multiple
/// options separated by newlines, allowing the game engine to randomly select
/// one option for display to the player.
extension MessageProvider {
    /// Selects a random line from a multiline message string.
    ///
    /// This method is used internally by the engine when processing messages
    /// that contain multiple response options (like atmospheric commands such
    /// as BREATHE, CRY, DANCE, etc.).
    ///
    /// - Parameters:
    ///   - multilineMessage: A string containing multiple lines, each representing a possible response
    ///   - randomNumberGenerator: The random number generator to use for selection
    /// - Returns: A single randomly selected line from the input string
    public func selectRandomLine(
        from multilineMessage: String,
        using randomNumberGenerator: inout some RandomNumberGenerator
    ) -> String {
        let lines =
            multilineMessage
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return multilineMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return lines.randomElement(using: &randomNumberGenerator) ?? lines[0]
    }
}

/// Extension to GameEngine for convenient random message selection.
extension GameEngine {
    /// Selects a random message from a MessageKey that may contain multiple options.
    ///
    /// This method automatically handles both single-line and multi-line messages.
    /// For multi-line messages (typically used for atmospheric responses),
    /// it randomly selects one line for display.
    ///
    /// - Parameter key: The MessageKey to process
    /// - Returns: A single message string, randomly selected if the key contains multiple options
    public func randomMessage(for key: MessageKey) async -> String {
        let message = messageProvider.message(for: key)
        let lines = message.split(separator: "\n", omittingEmptySubsequences: true)

        // If it's a single line or empty, return as-is
        guard lines.count > 1 else {
            return message.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Multiple lines - select randomly
        var rng = randomNumberGenerator
        defer { randomNumberGenerator = rng }
        return messageProvider.selectRandomLine(from: message, using: &rng)
    }
}
