import Foundation
import Markdown

/// A basic implementation of `IOHandler` that interacts with the standard console.
@MainActor
public struct ConsoleIOHandler: IOHandler {
    public init() {}

    // --- Output Methods ---

    public func print(_ markdown: String, style: TextStyle, newline: Bool) {
        Swift.print(MarkdownParser.parse(markdown), terminator: newline ? "\n\n" : "")
        fflush(stdout)
    }

    public func showStatusLine(roomName: String, score: Int, turns: Int) {
        let width = 64
        let scoreCol = 42

        let maxRoomLen = scoreCol - 2
        let displayRoom = roomName.count > maxRoomLen ?
                          roomName.prefix(maxRoomLen - 1) + "…" : roomName
        let scoreStr = "Score: \(score)"
        let turnsStr = "Turns: \(turns)"
        let leftGap = displayRoom.padding(toLength: scoreCol, withPad: " ", startingAt: 0)
        let rightPartLen = width - (leftGap.count + scoreStr.count)
        let rightGap = String(repeating: " ", count: max(1, rightPartLen - turnsStr.count))

        Swift.print("❲ \(leftGap)\(scoreStr)\(rightGap)\(turnsStr) ❳")
        fflush(stdout)
    }

    public func clearScreen() {
        // ANSI escape codes to clear screen and move cursor to top-left.
        // \u{001B}[2J clears the entire screen.
        // \u{001B}[H moves cursor to home position (top-left).
        Swift.print("\u{001B}[2J\u{001B}[H", terminator: "")
        fflush(stdout)
    }

    // --- Input Methods ---

    public func readLine(prompt: String) -> String? {
        // Print the prompt without a newline.
        Swift.print(prompt, terminator: "")
        fflush(stdout)
        // Read input from the console.
        return Swift.readLine()
    }

    // --- Lifecycle Methods ---

    public func setup() {
        // No specific setup needed for basic console I/O.
    }

    public func teardown() {
        // No specific teardown needed.
        Swift.print("\nGame ended.") // Add a final message
    }
}
