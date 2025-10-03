import Foundation
import Logging

/// A basic implementation of `IOHandler` that interacts with the standard console
/// (standard input and standard output).
///
/// This handler is suitable for running games in a command-line environment. It prints
/// game output directly to the console and reads player input from it.
@MainActor
public struct ConsoleIOHandler: IOHandler {
    /// The current transcript recorder, if one is active.
    public var transcriptRecorder: TranscriptRecorder?

    /// <#Description#>
    public var markdownParser: MarkdownParser

    /// Internal logger for engine messages, warnings, and errors.
    private let logger = Logger(label: "com.samadhibot.Gnusto.ConsoleIOHandler")

    /// Initializes a new `ConsoleIOHandler`.
    public init(
        markdownParser: MarkdownParser = MarkdownParser()
    ) {
        self.markdownParser = markdownParser
    }

    // --- Output Methods ---

    /// Prints a Markdown-formatted string to the console with the specified style.
    ///
    /// The Markdown is parsed and rendered as plain text suitable for console display.
    ///
    /// - Parameters:
    ///   - markdown: The Markdown string to print.
    ///   - style: The `TextStyle` to apply (though console output is typically unstyled).
    ///   - newline: If `true`, a double newline is appended to the output.
    ///              If `false`, no terminator is added.
    public func print(_ markdown: String, style: TextStyle, newline: Bool) {
        Swift.print(
            markdownParser.parse(markdown),
            terminator: newline ? .paragraph : ""
        )
        try? FileHandle.standardOutput.synchronize()

        do {
            try transcriptRecorder?.write("\(markdown)\n")
        } catch {
            logger.error("ConsoleIOHandler error: \(error)")
        }
    }

    /// Displays the game's status line (current location, score, and turn count)
    /// in a formatted way on the console.
    ///
    /// - Parameters:
    ///   - roomName: The name of the player's current location.
    ///   - score: The player's current score.
    ///   - turns: The current number of turns elapsed.
    public func showStatusLine(roomName: String, score: Int, turns: Int) {
        let width = markdownParser.columns ?? 64
        let scoreCol = Int(0.65625 * Double(width))

        let maxRoomLen = scoreCol - 2
        let displayRoom =
            roomName.count > maxRoomLen ? roomName.prefix(maxRoomLen - 1) + "..." : roomName
        let scoreStr = "Score: \(score)"
        let turnsStr = "Turns: \(turns)"
        let leftGap = displayRoom.padding(toLength: scoreCol, withPad: " ", startingAt: 0)
        let rightPartLen = width - (leftGap.count + scoreStr.count)
        let rightGap = String(repeating: " ", count: max(1, rightPartLen - turnsStr.count))

        Swift.print("❲ \(leftGap)\(scoreStr)\(rightGap)\(turnsStr) ❳")
        try? FileHandle.standardOutput.synchronize()
    }

    /// Clears the console screen.
    ///
    /// This uses ANSI escape codes to clear the screen and move the cursor to the
    /// top-left corner. Its effectiveness may depend on the terminal emulator being used.
    public func clearScreen() {
        // ANSI escape codes to clear screen and move cursor to top-left.
        // \u{001B}[2J clears the entire screen.
        // \u{001B}[H moves cursor to home position (top-left).
        Swift.print("\u{001B}[2J\u{001B}[H", terminator: "")
        try? FileHandle.standardOutput.synchronize()

        try? transcriptRecorder?.write("\n---\n")
    }

    // --- Input Methods ---

    /// Reads a line of text from the console after displaying a prompt.
    ///
    /// - Parameter prompt: The string to display to the user before waiting for input.
    /// - Returns: The string entered by the user, or `nil` if an error occurs or EOF is reached.
    public func readLine(prompt: String) -> String? {
        // Print the prompt without a newline.
        Swift.print(prompt, terminator: "")
        try? FileHandle.standardOutput.synchronize()

        // Read input from the console.
        let input = Swift.readLine()

        do {
            try transcriptRecorder?.write("\n〉\(input ?? "<EOF>")\n\n")
        } catch {
            logger.error("ConsoleIOHandler error: \(error)")
        }

        return input
    }

    // --- Lifecycle Methods ---

    /// Performs any necessary setup for console I/O.
    ///
    /// For this basic console handler, no specific setup actions are required.
    public func setup() {
        // No specific setup needed for basic console I/O.
    }

    /// Performs any necessary teardown for console I/O when the game ends.
    ///
    /// Prints a "Game ended." message to the console.
    public func teardown() {
        // No specific teardown needed.
        Swift.print("\nGame ended.")  // Add a final message
    }
}
