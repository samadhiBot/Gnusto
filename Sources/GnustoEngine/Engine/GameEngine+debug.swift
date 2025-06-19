//import Foundation
//
//#if DEBUG
//
//// MARK: - Internal State Mutation (Testing & Engine Use Only)
//
//extension GameEngine {
//    /// Applies a `StateChange` directly to the game state.
//    ///
//    /// > Important: **Internal/Test Use Only**: This method is provided for internal engine
//    ///   operations and testing scenarios where direct state manipulation is necessary. Game
//    ///   developers should use the action handler system (`ActionResult.changes`) rather
//    ///   than calling this method directly.
//    ///
//    /// This method bypasses the normal action handler pipeline, including:
//    /// - Before/after turn event handlers
//    /// - Action validation
//    /// - Side effect processing
//    ///
//    /// Use this method only when:
//    /// - Setting up test scenarios that require specific game states
//    /// - Internal engine operations that need direct state access
//    /// - Implementing low-level engine functionality
//    ///
//    /// - Parameter change: The `StateChange` to apply to the game state.
//    /// - Throws: Re-throws any errors from `GameState.apply()`, including validation failures.
//    func apply(_ changes: StateChange?...) async throws {
//        for change in changes.compactMap(\.self) {
//            try await applyWithDynamicValidation(change)
//        }
//    }
//
//    func execute(_ input: String) async throws {
//        let parseResult = parser.parse(
//            input: input,
//            vocabulary: gameState.vocabulary,
//            gameState: gameState
//        )
//
//        // 3. Execute Command or Handle Error
//        switch parseResult {
//        case .success(let command):
//            if command.verb == .quit || shouldQuit { return }
//
//            await execute(command: command)
//
//        case .failure(let error):
//            await report(parseError: error)
//        }
//
//    }
//
//    /// Retrieves the complete history of all `StateChange`s applied to the `gameState`
//    /// since the game started or the state was last loaded.
//    ///
//    /// This can be useful for debugging or advanced game mechanics that need to inspect
//    /// past state transitions.
//    ///
//    /// - Returns: An array of `StateChange` objects, in the order they were applied.
//    func changeHistory() -> [StateChange] {
//        gameState.changeHistory
//    }
//}
//
//#endif
