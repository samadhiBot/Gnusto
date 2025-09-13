import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

struct FilesystemHandlerTests {
    let handler = TestFilesystemHandler()

    @Test("FilesystemHandler uses temporary directory by default")
    func testTestHandlerDefaultTempDirectory() throws {
        // Given: A test filesystem handler with default constructor
        let gameName = "TestGame"

        // When: Getting gnusto directory
        let directory = try handler.gnustoDirectory(for: gameName)

        // Then: Should be under temp directory
        let tempDir = FileManager.default.temporaryDirectory
        #expect(directory.path().hasPrefix(tempDir.path()))
        #expect(directory.lastPathComponent == "TestGame")
        #expect(FileManager.default.fileExists(atPath: directory.path()))

        // Cleanup
        try handler.cleanup()
    }

    @Test("FilesystemHandler cleanup removes test directory")
    func testTestHandlerCleanup() throws {
        // Given: A test filesystem handler with created directory
        let gameName = "TestGame"
        let directory = try handler.gnustoDirectory(for: gameName)

        // When: Directory exists before cleanup
        #expect(FileManager.default.fileExists(atPath: directory.path()))

        // And: Cleanup is called
        try handler.cleanup()

        // Then: Directory should no longer exist
        let baseDir = directory.deletingLastPathComponent()
        #expect(!FileManager.default.fileExists(atPath: baseDir.path()))
    }

    @Test("FilesystemHandler saves and loads files correctly")
    func testTestHandlerFileOperations() throws {
        // Given: A test filesystem handler
        let gameName = "TestGame"
        let filename = "testsave"
        let testData = "test save data".data(using: .utf8)!

        // When: Creating save file URL and writing data
        let saveURL = try handler.saveFileURL(game: gameName, filename: filename)
        try testData.write(to: saveURL)

        // Then: File should exist and contain correct data
        #expect(FileManager.default.fileExists(atPath: saveURL.path()))
        let loadedData = try Data(contentsOf: saveURL)
        #expect(loadedData == testData)

        // Cleanup
        try handler.cleanup()
    }

    // MARK: - Timestamp Tests

    @Test("FilesystemHandler generates correctly formatted timestamps")
    func testTimestampFormatting() {
        // Given: A specific date
        let testDate = Date(timeIntervalSince1970: 1_735_120_500)

        // When: Generating timestamp
        let timestamp = TestFilesystemHandler.timestamp(for: testDate)

        // Then: Should have correct format (timezone-agnostic)
        let timestampRegex = /\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}/
        #expect(timestamp.wholeMatch(of: timestampRegex) != nil)
    }

    @Test("FilesystemHandler pads single digits with zeros")
    func testTimestampPadding() {
        // Given: A date with single digit components
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: 2024,
            month: 1,
            day: 5,
            hour: 9,
            minute: 3
        )
        let testDate = components.date!

        // When: Generating timestamp
        let timestamp = TestFilesystemHandler.timestamp(for: testDate)

        // Then: Should pad with zeros
        #expect(timestamp == "2024.01.05-09.03")
    }

    @Test("FilesystemHandler timestamp uses current date by default")
    func testTimestampDefaultDate() {
        // When: Generating timestamp without date
        let timestamp = TestFilesystemHandler.timestamp()

        // Then: Should have correct format (we can't test exact value since it's current time)
        let timestampRegex = /\d{4}\.\d{2}\.\d{2}-\d{2}\.\d{2}/
        #expect(timestamp.wholeMatch(of: timestampRegex) != nil)
    }

    // MARK: - Game Name Sanitization Tests

    @Test("FilesystemHandler sanitizes special characters in game names")
    func testGameNameSanitization() throws {
        // Given: Various handlers and game names with special characters

        let testCases = [
            ("Zork I: The Great Underground Empire", "ZorkITheGreatUndergroundEmpire"),
            ("Game-Name_With.Various!Characters", "GameName_WithVariousCharacters"),
            ("Simple Game", "SimpleGame"),
            ("123 Numbers & Symbols #$%", "123NumbersSymbols"),
            ("", "Unknown"),
        ]

        for (input, expected) in testCases {
            // When: Getting directories for both handlers
            let testDir = try handler.gnustoDirectory(for: input)

            // Then: Both should sanitize the same way
            #expect(testDir.lastPathComponent == expected)
        }

        // Cleanup
        try handler.cleanup()
    }

    // MARK: - Error Handling Tests

    @Test("FilesystemHandler handles file system errors gracefully")
    func testFileSystemErrorHandling() throws {
        // Given: A test filesystem handler

        // When: Trying to create files in directories that don't exist yet
        // (This should work because the handler creates directories)
        let saveURL = try handler.saveFileURL(game: "TestGame", filename: "test")
        let transcriptURL = try handler.transcriptFileURL(game: "TestGame", date: Date())

        // Then: URLs should be created successfully
        #expect(saveURL.pathExtension == "gnusto")
        #expect(transcriptURL.pathExtension == "md")

        // And: Parent directories should exist
        #expect(
            FileManager.default.fileExists(atPath: saveURL.deletingLastPathComponent().path())
        )
        #expect(
            FileManager.default.fileExists(atPath: transcriptURL.deletingLastPathComponent().path())
        )

        // Cleanup
        try handler.cleanup()
    }

    // MARK: - Integration Tests

    @Test("FilesystemHandler works correctly with different file types")
    func testMultipleFileTypes() throws {
        // Given: A test filesystem handler
        let gameName = "MultiFileTest"

        // When: Creating multiple file URLs
        let saveURL1 = try handler.saveFileURL(game: gameName, filename: "save1")
        let saveURL2 = try handler.saveFileURL(game: gameName, filename: "save2")
        let transcriptURL = try handler.transcriptFileURL(game: gameName, date: Date())

        // Then: All should be in the same game directory
        let gameDir = try handler.gnustoDirectory(for: gameName)
        #expect(saveURL1.deletingLastPathComponent() == gameDir)
        #expect(saveURL2.deletingLastPathComponent() == gameDir)
        #expect(transcriptURL.deletingLastPathComponent() == gameDir)

        // And: Each should have correct extensions
        #expect(saveURL1.pathExtension == "gnusto")
        #expect(saveURL2.pathExtension == "gnusto")
        #expect(transcriptURL.pathExtension == "md")

        // And: Filenames should be distinct
        #expect(saveURL1.lastPathComponent != saveURL2.lastPathComponent)
        #expect(saveURL1.lastPathComponent != transcriptURL.lastPathComponent)

        // Cleanup
        try handler.cleanup()
    }
}
