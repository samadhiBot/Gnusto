import Foundation

extension World {
    /// The possible states a game can be in.
    public enum State: Equatable {
        /// The game is running normally
        case running

        /// The player has won the game
        case victory(String)

        /// The player has lost the game
        case defeat(String)

        /// The player has quit the game
        case quit

        /// The message associated with the current state
        public var message: String? {
            switch self {
            case .running:
                return nil
            case .victory(let message):
                return message
            case .defeat(let message):
                return message
            case .quit:
                return "Thanks for playing!"
            }
        }
    }
}
