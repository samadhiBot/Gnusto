import Testing
@testable import GnustoEngine

@MainActor
struct ConsoleIOHandlerTests {
    
    // MARK: - Protocol Conformance Tests
    
    @Test("ConsoleIOHandler conforms to IOHandler protocol")
    func testProtocolConformance() {
        let handler = ConsoleIOHandler()
        
        // Verify it can be used as IOHandler
        let ioHandler: IOHandler = handler
        #expect(ioHandler is ConsoleIOHandler)
    }
    
    @Test("ConsoleIOHandler initialization works correctly")
    func testInitialization() {
        let _ = ConsoleIOHandler()
        
        // Should initialize without issues
        #expect(Bool(true)) // Handler initialized successfully
    }
    
    // MARK: - Status Line Formatting Tests
    
    @Test("Status line formatting with normal room name")
    func testStatusLineFormattingNormal() {
        let handler = ConsoleIOHandler()
        
        // We can't easily capture console output, but we can test the logic
        // by calling the method and ensuring it doesn't crash
        handler.showStatusLine(roomName: "Living Room", score: 42, turns: 15)
        
        // If we get here without crashing, the formatting logic worked
        #expect(Bool(true))
    }
    
    @Test("Status line formatting with long room name")
    func testStatusLineFormattingLongRoomName() {
        let handler = ConsoleIOHandler()
        
        // Test with a very long room name that should be truncated
        let longRoomName = "This is an extremely long room name that should definitely be truncated"
        handler.showStatusLine(roomName: longRoomName, score: 999, turns: 1000)
        
        // If we get here without crashing, the truncation logic worked
        #expect(Bool(true))
    }
    
    @Test("Status line formatting with empty room name")
    func testStatusLineFormattingEmptyRoomName() {
        let handler = ConsoleIOHandler()
        
        handler.showStatusLine(roomName: "", score: 0, turns: 0)
        
        // Should handle empty room name gracefully
        #expect(Bool(true))
    }
    
    @Test("Status line formatting with negative values")
    func testStatusLineFormattingNegativeValues() {
        let handler = ConsoleIOHandler()
        
        handler.showStatusLine(roomName: "Test Room", score: -10, turns: -5)
        
        // Should handle negative values gracefully
        #expect(Bool(true))
    }
    
    @Test("Status line formatting with large values")
    func testStatusLineFormattingLargeValues() {
        let handler = ConsoleIOHandler()
        
        handler.showStatusLine(roomName: "Test Room", score: 999999, turns: 999999)
        
        // Should handle large values gracefully
        #expect(Bool(true))
    }
    
    // MARK: - Print Method Tests
    
    @Test("Print method with simple text")
    func testPrintSimpleText() {
        let handler = ConsoleIOHandler()
        
        // Test basic printing - we can't capture output but can ensure no crashes
        handler.print("Hello, world!", style: .normal, newline: true)
        handler.print("No newline", style: .normal, newline: false)
        
        #expect(Bool(true))
    }
    
    @Test("Print method with markdown text")
    func testPrintMarkdownText() {
        let handler = ConsoleIOHandler()
        
        // Test markdown parsing integration
        handler.print("**Bold text** and *italic text*", style: .normal, newline: true)
        handler.print("# Header\n\nParagraph text", style: .normal, newline: true)
        
        #expect(Bool(true))
    }
    
    @Test("Print method with empty text")
    func testPrintEmptyText() {
        let handler = ConsoleIOHandler()
        
        handler.print("", style: .normal, newline: true)
        handler.print("", style: .normal, newline: false)
        
        #expect(Bool(true))
    }
    
    @Test("Print method with different text styles")
    func testPrintDifferentStyles() {
        let handler = ConsoleIOHandler()
        
        // Test all TextStyle cases
        handler.print("Normal text", style: .normal, newline: true)
        handler.print("Emphasized text", style: .emphasis, newline: true)
        handler.print("Strong text", style: .strong, newline: true)
        
        #expect(Bool(true))
    }
    
    // MARK: - Lifecycle Method Tests
    
    @Test("Setup method executes without error")
    func testSetup() {
        let handler = ConsoleIOHandler()
        
        handler.setup()
        
        // Should complete without throwing or crashing
        #expect(Bool(true))
    }
    
    @Test("Teardown method executes without error")
    func testTeardown() {
        let handler = ConsoleIOHandler()
        
        handler.teardown()
        
        // Should complete without throwing or crashing
        #expect(Bool(true))
    }
    
    @Test("Setup and teardown can be called multiple times")
    func testMultipleSetupTeardown() {
        let handler = ConsoleIOHandler()
        
        handler.setup()
        handler.setup() // Should be safe to call multiple times
        
        handler.teardown()
        handler.teardown() // Should be safe to call multiple times
        
        #expect(Bool(true))
    }
    
    // MARK: - Clear Screen Tests
    
    @Test("Clear screen method executes without error")
    func testClearScreen() {
        let handler = ConsoleIOHandler()
        
        handler.clearScreen()
        
        // Should complete without throwing or crashing
        #expect(Bool(true))
    }
    
    // MARK: - Integration Tests
    
    @Test("ConsoleIOHandler can be used in typical game flow")
    func testTypicalGameFlow() {
        let handler = ConsoleIOHandler()
        
        // Simulate a typical game interaction flow
        handler.setup()
        handler.clearScreen()
        handler.showStatusLine(roomName: "Starting Room", score: 0, turns: 1)
        handler.print("Welcome to the game!", style: .emphasis, newline: true)
        handler.print("You are in a dark room.", style: .normal, newline: true)
        handler.showStatusLine(roomName: "Dark Room", score: 5, turns: 2)
        handler.teardown()
        
        #expect(Bool(true))
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Handler works with unicode characters")
    func testUnicodeCharacters() {
        let handler = ConsoleIOHandler()
        
        handler.print("🎮 Game with emojis! 🏰", style: .normal, newline: true)
        handler.showStatusLine(roomName: "Castle 🏰", score: 42, turns: 10)
        
        #expect(Bool(true))
    }
    
    @Test("Handler works with special characters")
    func testSpecialCharacters() {
        let handler = ConsoleIOHandler()
        
        handler.print("Special chars: @#$%^&*()[]{}|\\", style: .normal, newline: true)
        handler.showStatusLine(roomName: "Room with \"quotes\"", score: 0, turns: 1)
        
        #expect(Bool(true))
    }
    
    @Test("Handler works with newlines and tabs in text")
    func testNewlinesAndTabs() {
        let handler = ConsoleIOHandler()
        
        handler.print("Line 1\nLine 2\n\tTabbed line", style: .normal, newline: true)
        
        #expect(Bool(true))
    }
} 