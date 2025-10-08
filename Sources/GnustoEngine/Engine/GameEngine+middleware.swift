import Foundation

// MARK: - Middleware Management

extension GameEngine {
    /// Returns middleware sorted by priority (highest first).
    var sortedMiddleware: [any GameMiddleware] {
        middleware.sorted { $0.priority > $1.priority }
    }

    /// Registers middleware with the engine.
    ///
    /// Middleware is typically registered during engine initialization from the
    /// game blueprint. Middleware components are executed in priority order
    /// (highest priority first) at various points in the game loop.
    ///
    /// - Parameter middleware: The middleware component to register
    func registerMiddleware(_ middleware: any GameMiddleware) {
        self.middleware.append(middleware)
    }

    /// Removes all middleware with the specified state key.
    ///
    /// This is useful for dynamically disabling middleware features during gameplay,
    /// though in most cases middleware should be configured statically via the blueprint.
    ///
    /// - Parameter stateKey: The state key of the middleware to remove
    func removeMiddleware(withStateKey stateKey: String) {
        middleware.removeAll { $0.stateKey == stateKey }
    }

    // MARK: - Middleware Execution Hooks

    /// Executes the `beforeTurn` hook for all registered middleware.
    ///
    /// This is called at the start of each turn, before player input is read.
    /// If any middleware returns `.handled`, remaining middleware is skipped
    /// and the turn is considered handled.
    ///
    /// - Returns: `.continue` if normal turn processing should proceed, or
    ///           `.handled` if middleware has handled the entire turn
    func executeBeforeTurnMiddleware() async throws -> MiddlewareResult {
        let context = MiddlewareContext(engine: self)
        for mw in sortedMiddleware {
            let result = try await mw.beforeTurn(context: context)
            if case .handled = result {
                return result
            }
        }
        return .continue
    }

    /// Executes the `beforeCommandExecution` hook for all registered middleware.
    ///
    /// This is called after parsing succeeds, before command execution begins.
    /// Middleware can modify the command or short-circuit execution entirely.
    ///
    /// - Parameter command: The parsed command about to be executed
    /// - Returns: `.continue` with the (possibly modified) command to execute, or
    ///           `.skip` if middleware has handled the command
    func executeBeforeCommandMiddleware(
        command: Command
    ) async throws -> CommandMiddlewareResult {
        let context = MiddlewareContext(engine: self)
        var currentCommand = command

        for mw in sortedMiddleware {
            let result = try await mw.beforeCommandExecution(
                command: currentCommand,
                context: context
            )
            switch result {
            case .continue(let modifiedCommand):
                currentCommand = modifiedCommand
            case .skip(let actionResult):
                return .skip(actionResult)
            }
        }

        return .continue(currentCommand)
    }

    /// Executes the `afterCommandExecution` hook for all registered middleware.
    ///
    /// This is called after command execution completes, with the action result.
    /// Middleware can modify the result or add additional effects. Each middleware
    /// receives the result from the previous middleware in the chain.
    ///
    /// - Parameters:
    ///   - command: The command that was executed
    ///   - result: The result of command execution
    /// - Returns: The (possibly modified) action result
    func executeAfterCommandMiddleware(
        command: Command,
        result: ActionResult
    ) async throws -> ActionResult {
        let context = MiddlewareContext(engine: self)
        var currentResult = result

        for mw in sortedMiddleware {
            currentResult = try await mw.afterCommandExecution(
                command: command,
                result: currentResult,
                context: context
            )
        }

        return currentResult
    }

    /// Executes the `beforeTimeAdvancement` hook for all registered middleware.
    ///
    /// This is called before fuses and daemons tick. If any middleware returns
    /// `.handled`, time advancement is skipped for this turn.
    ///
    /// - Returns: `.continue` if time should advance normally, or `.handled` to skip
    func executeBeforeTimeAdvancementMiddleware() async throws -> MiddlewareResult {
        let context = MiddlewareContext(engine: self)
        for mw in sortedMiddleware {
            let result = try await mw.beforeTimeAdvancement(context: context)
            if case .handled = result {
                return result
            }
        }
        return .continue
    }

    /// Executes the `afterTurn` hook for all registered middleware.
    ///
    /// This is called at the end of each turn, after all other processing.
    /// This hook cannot prevent further processing, as the turn is complete.
    func executeAfterTurnMiddleware() async throws {
        let context = MiddlewareContext(engine: self)
        for mw in sortedMiddleware {
            try await mw.afterTurn(context: context)
        }
    }

    // MARK: - Middleware State Persistence

    /// Saves the state of all registered middleware for game persistence.
    ///
    /// This is called when the player saves their game. Each middleware can
    /// return state data to be included in the save file.
    ///
    /// - Returns: A dictionary mapping middleware state keys to their saved state
    func saveMiddlewareState() async throws -> [String: any Codable & Sendable] {
        let context = MiddlewareContext(engine: self)
        var savedStates: [String: any Codable & Sendable] = [:]

        for mw in middleware {
            if let state = try await mw.saveState(context: context) {
                savedStates[mw.stateKey] = state
            }
        }

        return savedStates
    }

    /// Restores middleware state from a saved game.
    ///
    /// This is called when the player restores a saved game. Each middleware
    /// receives its previously saved state (if any).
    ///
    /// - Parameter savedStates: Dictionary mapping middleware state keys to saved state
    func restoreMiddlewareState(_ savedStates: [String: any Codable & Sendable]) async throws {
        let context = MiddlewareContext(engine: self)

        for mw in middleware {
            if let state = savedStates[mw.stateKey] {
                try await mw.restoreState(state, context: context)
            }
        }
    }
}
