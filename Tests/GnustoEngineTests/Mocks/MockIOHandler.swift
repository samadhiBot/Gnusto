import Foundation
import Markdown

@testable import GnustoEngine

/// A mock implementation of the `IOHandler` protocol for testing purposes.
@MainActor
final class MockIOHandler: IOHandler {
    // — Recorded Output —
    struct OutputCall: Equatable, Sendable {
        let text: String
        let style: TextStyle
        let newline: Bool
    }
    public private(set) var recordedOutput: [OutputCall] = []
    public private(set) var recordedStatusLines: [(roomName: String, score: Int, turns: Int)] = []
    public private(set) var clearScreenCallCount: Int = 0
    public private(set) var setupCallCount: Int = 0
    public private(set) var teardownCallCount: Int = 0

    // — Input Simulation —
    private var inputIndex = 0
    private var inputQueue: [String?]

    // — Initialization —
    init(_ commands: String?...) {
        inputQueue = commands
    }

    // — Configuration Methods (for tests) —
    /// Clears all recorded calls and resets input queue.
    func reset() {
        recordedOutput = []
        recordedStatusLines = []
        clearScreenCallCount = 0
        setupCallCount = 0
        teardownCallCount = 0
        inputIndex = 0
        inputQueue = []
    }

    /// Queues up lines to be returned by subsequent calls to `readLine`.
    func enqueueInput(_ lines: String?...) {
        inputQueue.append(contentsOf: lines)
    }

    // — IOHandler Conformance —

    func print(_ markdown: String, style: TextStyle, newline: Bool) {
        recordedOutput.append(
            OutputCall(
                text: MarkdownParser.parse(markdown),
                style: style,
                newline: newline
            )
        )
        // Optionally print to console during tests for debugging
    }

    func showStatusLine(roomName: String, score: Int, turns: Int) {
        recordedStatusLines.append((roomName: roomName, score: score, turns: turns))
    }

    func clearScreen() {
        clearScreenCallCount += 1
    }

    func readLine(prompt: String) -> String? {
        // Print the prompt using the print method so it can be recorded/verified if needed
        recordedOutput.append(
            OutputCall(
                text: prompt,
                style: .input,
                newline: false
            )
        )

        guard inputIndex < inputQueue.count else {
            // No more queued input, return nil (simulates EOF or error)
            return nil
        }
        let line = inputQueue[inputIndex]
        inputIndex += 1
        return line
    }

    func setup() {
        setupCallCount += 1
    }

    func teardown() {
        teardownCallCount += 1
    }

    func flush() async -> String {
        var commandIndex = 0
        var actualTranscript = ""
        for call in recordedOutput {
            if call.style == .input && call.text == "> " && !call.newline {
                actualTranscript += ">"
                if commandIndex < inputQueue.count {
                    if let command = inputQueue[commandIndex] {
                        actualTranscript += " \(command)\n"
                    }
                    commandIndex += 1
                } else {
                    actualTranscript += "\n"
                }
            } else if call.style != .input {
                actualTranscript += call.text
                if call.newline {
                    actualTranscript += "\n\n"
                }
            }
        }

        recordedOutput.removeAll()
        return actualTranscript
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
