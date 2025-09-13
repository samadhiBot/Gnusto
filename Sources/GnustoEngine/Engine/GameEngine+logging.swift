import Foundation
import Logging

// MARK: - Logging Utilities

extension GameEngine {
    /// Logs an error message to the engine's logger.
    ///
    /// Error messages are used for serious issues that indicate problems with game logic,
    /// state corruption, or other critical failures that should be investigated.
    ///
    /// - Parameter message: The error message to log.
    func logError(_ message: String) {
        logger.error(
            Logger.Message(
                stringLiteral: message.multiline()
            )
        )
    }

    /// Logs a warning message to the engine's logger.
    ///
    /// Warning messages are used for non-critical issues that don't prevent the game
    /// from continuing but may indicate potential problems or unexpected conditions.
    ///
    /// - Parameter message: The warning message to log.
    func logWarning(_ message: String) {
        logger.warning(
            Logger.Message(
                stringLiteral: message.multiline()
            )
        )
    }
}
