import Foundation

@testable import GnustoEngine

/// A mock implementation of the `IOHandler` protocol for comprehensive testing of interactive fiction games.
///
/// `MockIOHandler` captures all input/output operations during test execution, allowing tests to:
/// - Pre-queue user input commands for automated testing
/// - Verify exact game output including formatting and styling
/// - Test interactive prompts and user responses
/// - Simulate various input scenarios (EOF, invalid input, etc.)
///
/// ## Basic Usage
/// ```swift
/// // Create mock with pre-queued commands
/// let (engine, mockIO) = await GameEngine.test()
///
/// // Execute commands and verify output
/// try await engine.execute("take lamp")
/// let output = await mockIO.flush()
/// expectNoDifference(output, """
/// > take lamp
/// Taken.
/// """)
/// ```
///
/// ## Advanced Input Simulation
/// ```swift
/// // Simulate setup commands followed by test commands
/// let mockIO = MockIOHandler(
///     pre: "verbose\nbrief",  // Setup commands (output ignored)
///     "take lamp",            // Test command
///     "quit",                 // Another test command
///     nil                     // EOF simulation
/// )
/// ```
///
/// The mock automatically handles command echoing and output formatting to match
/// the expected interactive fiction transcript format.
@MainActor
public final class MockIOHandler: IOHandler {
    // MARK: - Recorded Output

    /// Represents a single output operation with its formatting context.
    public struct OutputCall: Equatable, Sendable {
        /// The text content that was output.
        let text: String
        /// The formatting style applied to the text.
        let style: TextStyle
        /// Whether a newline was added after the text.
        let newline: Bool
    }

    /// All output calls made during the test session, in chronological order.
    public private(set) var recordedOutput: [OutputCall] = []

    /// All status line updates made during the test session.
    public private(set) var recordedStatusLines: [(roomName: String, score: Int, turns: Int)] = []

    /// Number of times the screen was cleared during testing.
    public private(set) var clearScreenCallCount: Int = 0

    /// Number of setup commands that were processed (output from these is ignored).
    public private(set) var setupCommandCount: Int = 0

    /// Number of times teardown was called.
    public private(set) var teardownCallCount: Int = 0

    // MARK: - Input Simulation

    /// Current position in the input queue.
    private var inputIndex = 0

    /// Pre-queued input lines to be returned by `readLine()` calls.
    private var inputQueue: [String?]

    /// Number of times setup was called.
    private var setupCallCount: Int = 0

    // MARK: - Transcript Simulation

    /// Optional transcript recorder for capturing game sessions.
    public var transcriptRecorder: TranscriptRecorder?

    // MARK: - Markdown Processing

    /// Parser used to convert Markdown output to plain text for testing.
    public var markdownParser: MarkdownParser

    // MARK: - Initialization
    /// Creates a mock IO handler with setup commands followed by test commands.
    ///
    /// Setup commands are executed first and their output is ignored, allowing tests
    /// to configure game state without cluttering the verification output.
    ///
    /// - Parameters:
    ///   - setup: Newline-separated setup commands (output will be ignored).
    ///   - commands: Variadic list of test commands. Use `nil` to simulate EOF.
    public init(
        pre setup: String,
        _ commands: String?...
    ) {
        markdownParser = MarkdownParser.testParser()
        let setupCommands = setup.components(separatedBy: .newlines).filter(\.isNotEmpty)
        if commands.count == 1, let multi = commands.first??.components(separatedBy: .newlines) {
            inputQueue = setupCommands + multi
        } else {
            inputQueue = setupCommands + commands
        }
        setupCommandCount = setupCommands.count
    }

    /// Creates a mock IO handler with a queue of test commands.
    ///
    /// - Parameter commands: Variadic list of commands to execute. Use `nil` to simulate EOF.
    public init(_ commands: String?...) {
        markdownParser = MarkdownParser.testParser()
        if commands.count == 1, let multi = commands.first??.components(separatedBy: .newlines) {
            inputQueue = multi
        } else {
            inputQueue = commands
        }
    }

    // MARK: - Test Configuration

    /// Clears all recorded calls and resets input queue.
    public func reset() {
        recordedOutput = []
        recordedStatusLines = []
        clearScreenCallCount = 0
        setupCallCount = 0
        setupCommandCount = 0
        teardownCallCount = 0
        inputIndex = 0
        inputQueue = []
    }

    /// Queues up lines to be returned by subsequent calls to `readLine`.
    public func enqueueInput(_ lines: String?...) {
        inputQueue.append(contentsOf: lines)
    }

    // MARK: - IOHandler Conformance

    public func print(_ markdown: String, style: TextStyle, newline: Bool) {
        if setupCommandCount > 0 && inputIndex == setupCommandCount {
            recordedOutput.removeAll()
        } else {
            recordedOutput.append(
                OutputCall(
                    text: markdownParser.parse(markdown),
                    style: style,
                    newline: newline
                )
            )
        }
    }

    public func showStatusLine(roomName: String, score: Int, turns: Int) {
        recordedStatusLines.append((roomName: roomName, score: score, turns: turns))
    }

    public func clearScreen() {
        clearScreenCallCount += 1
    }

    public func readLine(prompt: String) -> String? {
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
        if let line {
            recordedOutput.append(
                OutputCall(
                    text: " \(line)",
                    style: .input,
                    newline: true
                )
            )
        }

        return line
    }

    public func setup() {
        setupCallCount += 1
    }

    public func teardown() {
        teardownCallCount += 1
    }

    /// Flushes all recorded output and returns it as a formatted transcript.
    ///
    /// This method processes all recorded output calls to produce a clean transcript
    /// that matches the expected interactive fiction format:
    /// - Commands are prefixed with "> "
    /// - Game output follows immediately after
    /// - Paragraphs are separated by double newlines
    /// - Prompts and responses are handled appropriately
    ///
    /// After flushing, the recorded output is cleared for subsequent test phases.
    ///
    /// - Returns: A formatted transcript string suitable for test verification.
    public func flush() async -> String {
        var actualTranscript = ""
        var index = 0
        while index < recordedOutput.count {
            let call = recordedOutput[index]

            if call.style == .input && call.text.hasPrefix("> ") && call.newline {
                // Main command (like "> quit")
                actualTranscript += call.text
                if call.newline {
                    actualTranscript = actualTranscript.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) + .linebreak
                }
            } else if call.style == .input && !call.newline {
                // Check if the next call is a user response to this prompt
                if index + 1 < recordedOutput.count && recordedOutput[index + 1].style == .input
                    && recordedOutput[index + 1].newline
                {
                    // Prompt (like "> " or quit confirmation prompt)
                    actualTranscript += call.text.rightTrimmed

                    let response = recordedOutput[index + 1]

                    // Check if this is the main prompt ("> ") with a response
                    if call.text == "> " {
                        // For main prompt, combine prompt and response on same line
                        actualTranscript += response.text
                        actualTranscript = actualTranscript.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ) + .linebreak
                        index += 1  // Skip the response since we handled it
                    } else {
                        // For custom prompts, keep response separate but don't add extra newline
                        actualTranscript += response.text
                        if response.newline {
                            actualTranscript = actualTranscript.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ) + .linebreak
                        }
                        index += 1  // Skip the response since we handled it
                    }
                } else {
                    // Prompt (like "> " or quit confirmation prompt)
                    actualTranscript += call.text

                    // No user response (EOF case), add newline after prompt
                    actualTranscript = actualTranscript.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) + .linebreak
                }
            } else if call.style == .input && call.newline {
                // User response to a prompt (if not already handled above)
                actualTranscript += call.text
                if call.newline {
                    actualTranscript = actualTranscript.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) + .linebreak
                }
            } else if call.style != .input {
                actualTranscript += call.text
                if call.newline {
                    actualTranscript += .paragraph
                }
            }
            index += 1
        }

        recordedOutput.removeAll()
        return
            actualTranscript
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing(/\n{3,}/, with: String.paragraph)
    }
}
