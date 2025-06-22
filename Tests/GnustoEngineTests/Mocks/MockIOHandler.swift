import Foundation

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
    init(
        _ setup: [String] = [],
        _ commands: String?...
    ) {
        inputQueue = setup + commands
    }

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

        // Record the user's response so it appears in the output
        if let line = line {
            recordedOutput.append(
                OutputCall(
                    text: " \(line)",  // Add space prefix for proper formatting
                    style: .input,
                    newline: true
                )
            )
        }

        return line
    }

    func setup() {
        setupCallCount += 1
    }

    func teardown() {
        teardownCallCount += 1
    }

    func flush() async -> String {
        var actualTranscript = ""
        var i = 0
        while i < recordedOutput.count {
            let call = recordedOutput[i]

            if call.style == .input && call.text.hasPrefix("> ") && call.newline {
                // Main command (like "> quit")
                actualTranscript += call.text
                if call.newline {
                    actualTranscript += "\n"
                }
            } else if call.style == .input && !call.newline {
                // Custom prompt (like quit confirmation prompt)
                actualTranscript += call.text

                // Check if the next call is a user response to this prompt
                if i + 1 < recordedOutput.count &&
                    recordedOutput[i + 1].style == .input &&
                    recordedOutput[i + 1].newline {
                    // There's a user response following this prompt, don't add newline here
                } else {
                    // No user response (EOF case), add newline after prompt
                    actualTranscript += "\n"
                }
            } else if call.style == .input && call.newline {
                // User response to a prompt
                actualTranscript += call.text
                if call.newline {
                    actualTranscript += "\n"
                }
            } else if call.style != .input {
                actualTranscript += call.text
                if call.newline {
                    actualTranscript += "\n\n"
                }
            }
            i += 1
        }

        recordedOutput.removeAll()
        return actualTranscript
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
