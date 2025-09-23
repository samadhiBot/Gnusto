import Foundation
import GnustoEngine

/// A filesystem handler implementation designed for unit testing that operates in isolated temporary directories.
///
/// `TestFilesystemHandler` provides a safe testing environment by creating unique temporary directories
/// for each test instance, preventing test pollution and ensuring clean test isolation. It implements
/// the `FilesystemHandler` protocol while automatically managing temporary storage lifecycle.
///
/// ## Key Features
/// - **Test Isolation**: Each instance uses a unique temporary directory
/// - **Automatic Cleanup**: Provides methods to clean up test artifacts
/// - **Safe Testing**: Prevents accidental modification of user directories
/// - **Configurable**: Allows custom base directories when needed
///
/// ## Basic Usage
/// ```swift
/// let filesystemHandler = TestFilesystemHandler()
/// let (engine, mockIO) = await GameEngine.test(filesystemHandler: filesystemHandler)
///
/// // Run tests that involve file operations
/// try await engine.execute("save game")
///
/// // Clean up after test
/// try filesystemHandler.cleanup()
/// ```
///
/// ## Test Lifecycle Integration
/// ```swift
/// @Test func testSaveGame() async throws {
///     let filesystemHandler = TestFilesystemHandler()
///     defer { try? filesystemHandler.cleanup() }
///
///     // Test filesystem operations safely
/// }
/// ```
///
/// The handler automatically creates unique directories under the system's temporary directory,
/// ensuring no conflicts between concurrent tests or test runs.
public struct TestFilesystemHandler: FilesystemHandler {
    /// The base directory where all file operations for this test instance will be performed.
    ///
    /// This directory is automatically created as a unique subdirectory under the system's
    /// temporary directory, ensuring test isolation and preventing conflicts.
    public let baseDirectory: URL

    /// Creates a test filesystem handler with an isolated temporary directory.
    ///
    /// Each instance creates a unique directory under the system's temporary directory,
    /// identified by a UUID to ensure complete isolation between test instances.
    /// The directory is created on-demand when first accessed by filesystem operations.
    ///
    /// - Parameter baseDirectory: Optional custom base directory. If `nil`, uses system
    ///                            temporary directory with unique UUID suffix.
    public init(baseDirectory: URL? = nil) {
        self.baseDirectory =
            baseDirectory
            ?? FileManager.default.temporaryDirectory.appending(
                path: "GnustoTest-\(UUID().uuidString)",
                directoryHint: .isDirectory
            )
    }

    /// Removes the test directory and all its contents from the filesystem.
    ///
    /// This method should be called during test teardown to ensure no temporary files
    /// are left behind. It safely removes the entire test directory tree, including
    /// all subdirectories and files created during testing.
    ///
    /// ## Usage in Tests
    /// ```swift
    /// @Test func testFileOperations() async throws {
    ///     let filesystemHandler = TestFilesystemHandler()
    ///     defer { try? filesystemHandler.cleanup() }
    ///
    ///     // Perform test operations...
    /// }
    /// ```
    ///
    /// - Throws: `FileManager` errors if the directory cannot be removed, though this is
    ///           typically safe to ignore in test contexts using `try?`.
    ///
    /// > Note: This method is safe to call multiple times or on non-existent directories.
    public func cleanup() throws {
        if FileManager.default.fileExists(atPath: baseDirectory.path()) {
            try FileManager.default.removeItem(at: baseDirectory)
        }
    }
}
