import GnustoEngine

@MainActor
extension Components {
    /// Functionality related to the Iron Door puzzle.
    enum IronDoorPuzzle {
        // MARK: - Constants

        /// Constants for puzzle elements
        enum Constants {
            /// ID for the locked door item
            static let doorID: ItemID = "ironDoor"

            /// ID for the key item
            static let keyID: ItemID = "rustyKey"

            /// Flag for door unlocked state in game state flags
            static let doorUnlockedFlag = "iron_door_unlocked"
        }

        // Note: Logic for unlocking/using the door will likely be handled
        // via ActionHandlers or specific hooks (e.g., onExamineItem, onEnterRoom)
        // which will reference these constants.
    }
}
