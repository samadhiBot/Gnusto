import Foundation

@MainActor
public protocol IOHandler: Sendable {

    // --- Output Methods ---

    /// Displays a string of text to the player.
    ///
    /// - Parameters:
    ///   - markdown: The markdown text to display.
    ///   - style: A hint for the desired text style (implementation specific).
    ///   - newline: Whether to append a newline character after the text (defaults to true).
    func print(_ markdown: String, style: TextStyle, newline: Bool)

    /// A convenience function to print normal text with a newline.
    func print(_ markdown: String)

    /// A convenience function to print styled text with a newline.
    func print(_ markdown: String, style: TextStyle)

    /// Displays the top status line (typically Room Name and Score/Turns).
    ///
    /// Implementations are responsible for formatting this information appropriately.
    ///
    /// - Parameters:
    ///   - roomName: The name of the current room.
    ///   - score: The current score.
    ///   - turns: The current turn count.
    func showStatusLine(roomName: String, score: Int, turns: Int)

    /// Clears the main output area (excluding potentially the status line).
    func clearScreen()

    // --- Input Methods ---

    /// Reads a line of input from the player.
    ///
    /// This function should block until input is received.
    ///
    /// - Parameter prompt: A prompt string to display before waiting for input (e.g., "> ").
    /// - Returns: The input string entered by the player, or nil if input fails or is EOF.
    func readLine(prompt: String) -> String?

    // --- Lifecycle Methods ---

    /// Performs any necessary setup before interaction begins (e.g., initializing UI).
    func setup()

    /// Performs any necessary cleanup after interaction ends (e.g., restoring terminal state).
    func teardown()
}

// Default implementations for convenience print methods
public extension IOHandler {
    func print(_ markdown: String) {
        self.print(markdown, style: .normal, newline: true)
    }

    func print(_ markdown: String, style: TextStyle) {
        self.print(markdown, style: style, newline: true)
    }
}
