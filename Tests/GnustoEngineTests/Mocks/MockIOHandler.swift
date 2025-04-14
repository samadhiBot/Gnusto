import Foundation
@testable import GnustoEngine
import Testing

/// A mock implementation of the `IOHandler` protocol for testing purposes.
/// This actor runs on the dedicated IOActor.
@IOActor
final class MockIOHandler: IOHandler {

    // --- Recorded Output ---
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

    // --- Input Simulation ---
    private var inputQueue: [String?] = []

    // --- Initialization ---
    init() {}

    // --- Configuration Methods (for tests) ---
    /// Clears all recorded calls and resets input queue.
    func reset() {
        recordedOutput = []
        recordedStatusLines = []
        clearScreenCallCount = 0
        setupCallCount = 0
        teardownCallCount = 0
        inputQueue = []
    }

    /// Queues up lines to be returned by subsequent calls to `readLine`.
    func enqueueInput(_ lines: String?...) {
        inputQueue.append(contentsOf: lines)
    }

    // --- IOHandler Conformance ---

    func print(_ text: String, style: TextStyle, newline: Bool) {
        let call = OutputCall(text: text, style: style, newline: newline)
        recordedOutput.append(call)
        // Optionally print to console during tests for debugging
        // Swift.print("[MockIO] Print: \(text), Style: \(style), Newline: \(newline)")
    }

    // Default implementations provided by protocol extension handle:
    // func print(_ text: String)
    // func print(_ text: String, style: TextStyle)

    func showStatusLine(roomName: String, score: Int, turns: Int) {
        recordedStatusLines.append((roomName: roomName, score: score, turns: turns))
        // Swift.print("[MockIO] Status: \(roomName) Score: \(score) Turns: \(turns)")
    }

    func clearScreen() {
        clearScreenCallCount += 1
        // Swift.print("[MockIO] ClearScreen")
    }

    func readLine(prompt: String) -> String? {
        // Print the prompt using the print method so it can be recorded/verified if needed
        self.print(prompt, style: .input, newline: false)

        guard !inputQueue.isEmpty else {
            // No more queued input, return nil (simulates EOF or error)
            // Swift.print("[MockIO] ReadLine: No input queued, returning nil")
            return nil
        }
        let line = inputQueue.removeFirst()
        // Swift.print("[MockIO] ReadLine: Returning '\(line ?? "nil")'")
        return line
    }

    func setup() {
        setupCallCount += 1
        // Swift.print("[MockIO] Setup")
    }

    func teardown() {
        teardownCallCount += 1
        // Swift.print("[MockIO] Teardown")
    }

    // MARK: - Test Accessors

    // Use async getters to access state safely from tests
    func getRecordedOutput() async -> [OutputCall] { return recordedOutput }
    func getRecordedStatusLines() async -> [(roomName: String, score: Int, turns: Int)] { return recordedStatusLines }
    func getClearScreenCallCount() async -> Int { return clearScreenCallCount }
    func getSetupCallCount() async -> Int { return setupCallCount }
    func getTeardownCallCount() async -> Int { return teardownCallCount }
}
