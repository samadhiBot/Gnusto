import CustomDump
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
/// await mockIO.expectOutput("""
///    > take lamp
///    Taken.
///    """)
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
    public private(set) var recordedStatusLines: [RecordedStatusLine] = []

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
            inputQueue = setupCommands + multi.filter(\.isNotEmpty)
        } else {
            // Preserve nil values (EOF simulation) but convert empty strings to nil
            inputQueue = setupCommands + commands.map { $0?.isEmpty == true ? nil : $0 }
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
        recordedStatusLines.append(
            RecordedStatusLine(
                roomName: roomName,
                score: score,
                turns: turns
            )
        )
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
                    actualTranscript =
                        actualTranscript.trimmingCharacters(
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
                        actualTranscript =
                            actualTranscript.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ) + .linebreak
                        index += 1  // Skip the response since we handled it
                    } else {
                        // For custom prompts, keep response separate but don't add extra newline
                        actualTranscript += response.text
                        if response.newline {
                            actualTranscript =
                                actualTranscript.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ) + .linebreak
                        }
                        index += 1  // Skip the response since we handled it
                    }
                } else {
                    // Prompt (like "> " or quit confirmation prompt)
                    actualTranscript += call.text

                    // No user response (EOF case), add newline after prompt
                    actualTranscript =
                        actualTranscript.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ) + .linebreak
                }
            } else if call.style == .input && call.newline {
                // User response to a prompt (if not already handled above)
                actualTranscript += call.text
                if call.newline {
                    actualTranscript =
                        actualTranscript.trimmingCharacters(
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

// MARK: - Test helper

extension MockIOHandler {
    /// Flushes recorded output and verifies it matches the expected transcript.
    ///
    /// This convenience method combines `flush()` and `expectNoDifference()` to streamline
    /// test verification. It captures all recorded output since the last flush, formats it
    /// as an interactive fiction transcript, and compares it against the expected output.
    ///
    /// ## Usage
    /// ```swift
    /// try await engine.execute("take lamp")
    /// try await mockIO.expectOutput("""
    ///     > take lamp
    ///     Taken.
    ///     """)
    /// ```
    ///
    /// - Parameters:
    ///   - output: The expected transcript output to compare against.
    ///   - message: Optional custom failure message for test diagnostics.
    ///   - fileID: Source file identifier for test failure reporting.
    ///   - filePath: Source file path for test failure reporting.
    ///   - line: Source line number for test failure reporting.
    ///   - column: Source column number for test failure reporting.
    /// - Throws: Test failure if the actual output doesn't match expectations.
    public func expectOutput(
        _ output: @autoclosure () -> String,
        _ message: @autoclosure () -> String? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) async {
        let actual = await flush()
        expectNoDifference(
            actual,
            output(),
            message(),
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - RecordedStatusLine

extension MockIOHandler {
    /// Represents a captured status line update during test execution.
    ///
    /// Status lines in interactive fiction games typically display contextual information
    /// such as the current room, player score, and turn count. This structure captures
    /// these updates for test verification.
    public struct RecordedStatusLine {
        /// The name of the current room or location.
        let roomName: String
        /// The player's current score.
        let score: Int
        /// The current turn number.
        let turns: Int
    }
}
