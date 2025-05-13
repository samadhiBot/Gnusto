import Foundation

/// A basic implementation of `IOHandler` that interacts with the standard console.
@MainActor
public struct ConsoleIOHandler: IOHandler {
    public init() {}

    // --- Output Methods ---

    public func print(_ text: String, style: TextStyle, newline: Bool) {
        // Basic implementation ignores style for now.
        // Use Swift.print to avoid potential conflicts if extensions arise.
        Swift.print(text, terminator: newline ? "\n" : "")
        // Ensure output is immediately visible, especially relevant if buffering occurs.
        fflush(stdout)
    }

    public func showStatusLine(roomName: String, score: Int, turns: Int) {
        let width = 70
        let scoreCol = 40

        // Truncate room name if too long
        let maxRoomLen = scoreCol - 2
        let displayRoom = roomName.count > maxRoomLen
        ? roomName.prefix(maxRoomLen - 1) + "…"
        : roomName

        let scoreStr = "Score: \(score)"
        let turnsStr = "Turns: \(turns)"

        // Compose left part (room name, padded to scoreCol)
        let leftPart = displayRoom.padding(toLength: scoreCol, withPad: " ", startingAt: 0)
        // Compose right part (turns, right-aligned)
        let rightPartLen = width - (leftPart.count + scoreStr.count)
        let rightPart = String(repeating: " ", count: max(1, rightPartLen - turnsStr.count)) + turnsStr

        // Final line
        let line = leftPart + scoreStr + rightPart

        // Separator
        let separator = String(repeating: "─", count: width)

        Swift.print("\n\(line)\n\(separator)")
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
