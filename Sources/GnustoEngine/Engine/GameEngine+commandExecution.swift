import Foundation

// swiftlint:disable file_length

// MARK: - Command Execution

extension GameEngine {
    /// Executes a parsed game command, orchestrating calls to event handlers and action handlers.
    ///
    /// This is a central method in processing player actions. It performs the following sequence:
    /// 1. **Item `beforeTurn` Events**: For every item in the player's current location or
    ///    inventory that has an `ItemEventHandler` registered for `.beforeTurn`,
    ///    executes that handler. If any handler returns `true` (indicating it fully handled
    ///    the command or turn) or sets `shouldQuit`, further processing of the command stops.
    /// 2. **Location `beforeTurn` Events**: If the player's current location has a
    ///    `LocationEventHandler` registered for `.beforeTurn`, executes it. If it returns `true`
    ///    or sets `shouldQuit`, further processing stops.
    /// 3. **Main Action Handling**: If the command was not fully handled by `beforeTurn` events:
    ///    a. Retrieves the appropriate `ActionHandler` for the command's verb from the
    ///       engine's `actionHandlers` registry.
    ///    b. If a handler is found:
    ///        i. Calls the handler's `validate(context:)` method. If validation throws an
    ///           `ActionResponse`, reports it and stops.
    ///       ii. Calls the handler's `process(context:)` method. This typically returns an
    ///           `ActionResult` containing state changes and a message.
    ///      iii. Applies any `StateChange`s from the `ActionResult` to `gameState`.
    ///       iv. Prints the `ActionResult.message` to the player.
    ///        v. Calls the handler's `postProcess(context:result:)` method for any final actions.
    ///       vi. Processes any `SideEffect`s from the `ActionResult`.
    ///    c. If no `ActionHandler` is found for the verb, reports an `ActionResponse.verbUnknown` error.
    /// 4. **Item `afterTurn` Events**: Similar to `beforeTurn`, executes `.afterTurn` item event handlers.
    /// 5. **Location `afterTurn` Events**: Similar to `beforeTurn`, executes `.afterTurn` location event handlers.
    /// 6. **Movement and Lighting Detection**: For movement commands (`.go`, `.climb`) and lighting commands
    ///    (`.turnOn`, `.turnOff`), detects location changes or lighting state changes and automatically
    ///    describes the current location with appropriate transition messages.
    ///
    /// Any `ActionResponse` errors thrown during this process are caught and reported to the player.
    /// Other errors are logged.
    ///
    /// - Parameter command: The `Command` object to execute.
    /// - Returns: Whether the command should consume a turn.
    func execute(command: Command) async throws -> Bool {
        var actionHandled = false
        var actionResponse: Error?  // To store error from object handlers
        var shouldConsumeTurn = true  // Default to consuming turn unless meta-command is used

        // Store the player's current location and lighting state before executing the command
        let locationBeforeCommand = await player.location
        let wasLitBeforeCommand = await locationBeforeCommand.isLit

        // --- Room BeforeTurn Hook ---
        if let locationHandler = locationEventHandlers[locationBeforeCommand.id] {
            do {
                if let result = try await locationHandler.handle(self, .beforeTurn(command)) {
                    // Room handler returned a result, process it
                    let shouldYield = try await processEventResult(result)
                    if !shouldYield {
                        return true  // Room handler handled everything
                    }
                    // If yielding, continue with normal processing
                }
            } catch {
                // Log error and potentially halt turn?
                logWarning("Error in room beforeTurn handler: \(error)")
                // Decide if this error should block the turn. For now, let's continue.
            }
            // Check if handler quit the game
            if shouldQuit { return true }
        }

        // --- Try Object Action Handlers ---

        // 1. Check Direct Objects Handlers
        // Skip for ALL commands - let action handlers determine which items to process internally
        if !actionHandled,
            actionResponse == nil,
            command.directObjects.isNotEmpty,
            !command.isAllCommand
        {
            for directObjectRef in command.directObjects {
                guard
                    case .item(let itemProxy) = directObjectRef,
                    let itemHandler = itemEventHandlers[itemProxy.id]
                else {
                    continue
                }

                // Ensure item is present before calling handler
                guard await itemProxy.hasSameLocationAsPlayer else {
                    continue
                }

                do {
                    if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                        // Object handler returned a result, process it
                        let shouldYield = try await processEventResult(result)
                        if !shouldYield {
                            return true  // Object handler handled everything
                        }
                        // If yielding, continue with normal processing
                    }
                } catch {
                    actionResponse = error
                    actionHandled = true  // Treat error as handled to prevent default handler
                    break  // Stop processing other objects if one throws an error
                }

                if shouldQuit { return true }
            }
        }

        // 2. Check Indirect Object Handler (only if DO didn't handle it and no error occurred)
        // ZIL precedence: Often, if a DO routine handled it (or errored), the IO routine wasn't called.
        // 2. Check Indirect Object Handler
        // Skip for ALL commands - let action handlers determine which items to process internally
        if !actionHandled,
            actionResponse == nil,
            !command.isAllCommand,
            case .item(let itemProxy) = command.indirectObject,
            let itemHandler = itemEventHandlers[itemProxy.id],
            await itemProxy.hasSameLocationAsPlayer
        {
            do {
                if let result = try await itemHandler.handle(self, .beforeTurn(command)) {
                    // Object handler returned a result, process it
                    let shouldYield = try await processEventResult(result)
                    if !shouldYield {
                        return true  // Object handler handled everything
                    }
                    // If yielding, continue with normal processing
                }
            } catch {
                actionResponse = error
                actionHandled = true
            }
        }

        // --- Execute Default Handler or Report Error ---

        if let actionResponse {
            // An object handler threw an error
            if let specificResponse = actionResponse as? ActionResponse {
                await ioHandler.print(
                    describe(specificResponse)
                )
            } else {
                logWarning("An unexpected error occurred in an object handler: \(actionResponse)")
                await ioHandler.print(
                    describe(.internalEngineError("\(actionResponse)"))
                )
            }
        } else if !actionHandled {
            // No object handler took charge, check for darkness before running default verb handler

            let isLit = await player.location.isLit

            // Retrieve verb definition to check requiresLight property
            // Note: Parser should ensure command.verbID exists in vocabulary
            // Correct: Look up the Verb definition directly
            guard vocabulary.verbs.first(where: { $0 == command.verb }) != nil else {
                // This case should ideally not be reached if parser validates verbs
                logWarning(
                    "Internal Error: Unknown verb ID '\(command.verb)' reached execution."
                )
                await ioHandler.print(
                    messenger.verbUnknown(command.verbPhrase)
                )
                return true
            }

            // Room is lit OR verb doesn't require light, proceed with default handler execution.
            guard let actionHandler = findActionHandler(for: command) else {
                // No handler registered for this verb (should match vocabulary definition)
                logWarning(
                    "Internal Error: No ActionHandler registered for verb ID '\(command.verb)'."
                )
                await ioHandler.print(
                    messenger.verbUnknown(command.verbPhrase)
                )
                return true
            }

            // Check if this handler consumes a turn
            shouldConsumeTurn = actionHandler.consumesTurn

            // If the room is dark and the handler requires light, report error.
            if !isLit && actionHandler.requiresLight {
                await ioHandler.print(
                    describe(.roomIsDark)
                )
            } else {
                // --- Execute Handler ---
                do {
                    // Use the unified process method (handles both validation and execution)
                    let result = try await actionHandler.process(
                        context: ActionContext(command, self)
                    )

                    // Process the result (apply changes, print message)
                    try await processActionResult(result)

                    // Call postProcess (even if default is empty)
                    try await actionHandler.postProcess(
                        command: command,
                        engine: self,
                        result: result
                    )

                } catch let actionResponse as ActionResponse {

                    let message = await describe(actionResponse)

                    // Log detailed errors separately
                    switch actionResponse {
                    case .internalEngineError(let msg):
                        logger.error("ActionResponse: Internal Engine Error: \(msg)")
                    case .invalidValue(let msg):
                        logger.error("ActionResponse: Invalid Value: \(msg)")
                    default:
                        logger.debug("\(type(of: actionHandler)): \(actionResponse)")
                    }

                    await ioHandler.print(message)

                } catch {
                    // Catch any other unexpected errors from handlers
                    await ioHandler.print(
                        messenger.internalEngineError(
                            "Unexpected error during handler execution: \(error)"
                        )
                    )
                }
                // --- End Execute Handler ---
            }
        }

        // --- Update Pronouns ---

        // Update pronoun based on the command's direct objects
        try await updatePronounForCommand(command)

        // --- Item AfterTurn Hooks ---

        // 1. Check Direct Objects AfterTurn Handlers
        if command.directObjects.isNotEmpty {
            for directObjectRef in command.directObjects {
                guard
                    case .item(let itemProxy) = directObjectRef,
                    let itemHandler = itemEventHandlers[itemProxy.id]
                else {
                    continue
                }

                // Ensure item is present before calling handler
                guard await itemProxy.hasSameLocationAsPlayer else {
                    continue
                }

                do {
                    if let result = try await itemHandler.handle(self, .afterTurn(command)) {
                        let shouldYield = try await processEventResult(result)
                        if !shouldYield {
                            return true
                        }
                        // If yielding, continue with normal processing
                    }
                } catch {
                    logWarning("Error in direct object afterTurn handler: \(error)")
                }

                if shouldQuit { return true }
            }
        }

        // 2. Check Indirect Object AfterTurn Handler
        if case .item(let itemProxy) = command.indirectObject,
            let itemHandler = itemEventHandlers[itemProxy.id],
            await itemProxy.hasSameLocationAsPlayer
        {
            do {
                if let result = try await itemHandler.handle(self, .afterTurn(command)) {
                    let shouldYield = try await processEventResult(result)
                    if !shouldYield {
                        return true
                    }
                    // If yielding, continue with normal processing
                }
            } catch {
                logWarning("Error in indirect object afterTurn handler: \(error)")
            }
            if shouldQuit { return true }
        }

        // --- Room AfterTurn Hook ---
        if let locationHandler = locationEventHandlers[locationBeforeCommand.id] {
            do {
                // Call handler, ignore return value, use correct enum case syntax
                if let result = try await locationHandler.handle(self, .afterTurn(command)) {
                    let shouldYield = try await processEventResult(result)
                    if !shouldYield {
                        return true
                    }
                    // If yielding, continue with normal processing
                }
            } catch {
                logWarning("Error in room afterTurn handler: \(error)")
            }
            // Check if handler quit the game
            if shouldQuit { return true }
        }

        // --- Movement and Lighting Detection ---
        do {
            try await handlePostCommandLocationUpdates(
                command: command,
                locationBeforeCommand: locationBeforeCommand.id,
                wasLitBeforeCommand: wasLitBeforeCommand
            )
        } catch {
            logError("Error handling post-command location updates: \(error)")
        }

        return shouldConsumeTurn
    }

    /// Finds the appropriate action handler for a given command.
    ///
    /// This method searches through all registered action handlers to find one that can
    /// process the given command based on:
    /// 1. The handler's verb list (if it specifies verbs)
    /// 2. The handler's syntax rules (for handlers that use specific syntax patterns)
    ///
    /// - Parameter command: The command to find a handler for
    /// - Returns: The action handler that can process this command, or nil if none found
    public func findActionHandler(for command: Command) -> ActionHandler? {
        var bestHandler: ActionHandler?
        var bestScore = 0

        for handler in actionHandlers {
            let score = scoreHandlerForCommand(handler: handler, command: command)
            if score > bestScore {
                bestScore = score
                bestHandler = handler
            }
        }

        return bestHandler
    }

    /// Scores how well an action handler matches a command.
    ///
    /// Evaluates each syntax rule in the handler and returns the highest score.
    /// The scoring is performed by `scoreSyntaxRuleForCommand` for each individual
    /// syntax rule, and the maximum score is returned.
    ///
    /// - Parameters:
    ///   - handler: The action handler to score
    ///   - command: The command to match against
    /// - Returns: Score (0 means no match, higher is better)
    func scoreHandlerForCommand(handler: ActionHandler, command: Command) -> Int {
        handler.syntax.map {
            scoreSyntaxRuleForCommand(
                syntaxRule: $0,
                command: command,
                synonyms: handler.synonyms
            )
        }.max() ?? 0
    }

    /// Checks if a handler's syntax rules could potentially match a command.
    ///
    /// This performs a basic compatibility check focusing on verb-specific patterns.
    /// For syntax rules that use `.specificVerb(verbID)`, we check if the command's
    /// verb matches that specific verbID.
    ///
    /// - Parameters:
    ///   - handler: The action handler to check
    ///   - command: The command to match against
    /// - Returns: True if the handler could potentially process this command
    func couldHandlerMatchCommand(_ handler: ActionHandler, _ command: Command) -> Bool {
        scoreHandlerForCommand(handler: handler, command: command) > 0
    }

    /// Scores how well a syntax rule matches a command.
    ///
    /// Uses an additive scoring system where each token in the syntax pattern
    /// contributes points based on how well it matches the command:
    ///
    /// **Verb Tokens:**
    /// - `.specificVerb(verb)`: +10 if matches exactly, -10 if doesn't
    /// - `.verb`: +9 if command verb is in synonyms, -9 if not
    ///
    /// **Object Tokens:**
    /// - `.directObject`: +1 if exactly 1 direct object present, -1 if not
    /// - `.directObjects`: +2 if any direct objects present, -2 if none
    /// - `.indirectObject`: +3 if exactly 1 indirect object present, -3 if not
    /// - `.indirectObjects`: +4 if any indirect objects present, -4 if none
    ///
    /// **Other Tokens:**
    /// - `.direction`: +5 if direction present, -5 if not
    /// - `.particle(particle)`: +6 if matches exactly, -6 if not
    ///
    /// **Requirements:**
    /// - Rule must contain at least one verb token (`.verb` or `.specificVerb`) to be valid
    /// - Returns 0 if no verb token is present, regardless of other matches
    ///
    /// - Parameters:
    ///   - syntaxRule: The syntax rule to score
    ///   - command: The command to match against
    ///   - synonyms: List of verbs that this handler recognizes
    /// - Returns: Total additive score (0 means no match, higher is better)
    public func scoreSyntaxRuleForCommand(
        syntaxRule: SyntaxRule,
        command: Command,
        synonyms: [Verb] = []
    ) -> Int {
        var score = 0
        var hasVerbToken = false

        for token in syntaxRule.pattern {
            switch token {
            case .specificVerb(let requiredVerb):
                // Specific verb requirement - must match exactly
                if command.verb == requiredVerb {
                    score += 10
                    hasVerbToken = true
                } else {
                    score -= 10
                }

            case .verb:
                // Generic verb token - any verb can match
                if synonyms.contains(command.verb) {
                    score += 9
                    hasVerbToken = true
                } else {
                    score -= 9
                }

            case .directObject:
                // Rule requires direct object(s)
                if command.directObjects.count == 1 {
                    score += 1  // Bonus for having required direct object
                } else {
                    score -= 1  // Rule requires direct object but command has none
                }

            case .directObjects:
                // Rule requires direct object(s)
                if command.directObjects.isNotEmpty {
                    score += 2  // Bonus for having required direct object
                } else {
                    score -= 2  // Rule requires direct object but command has none
                }

            case .indirectObject:
                // Rule requires indirect object(s)
                if command.indirectObjects.count == 1 {
                    score += 3  // Bonus for having required indirect object
                } else {
                    score -= 3  // Rule requires indirect object but command has none
                }

            case .indirectObjects:
                // Rule requires indirect object(s)
                if command.indirectObjects.isNotEmpty {
                    score += 4  // Bonus for having required indirect object
                } else {
                    score -= 4  // Rule requires indirect object but command has none
                }

            case .direction:
                // Rule expects direction
                if command.direction != nil {
                    score += 5  // Bonus for having direction when expected
                } else {
                    score -= 5  // Rule requires direction but command has none
                }

            case .particle(let requiredParticle):
                // Rule requires specific particle/preposition
                if let commandPreposition = command.preposition,
                    commandPreposition.rawValue.lowercased() == requiredParticle.lowercased()
                {
                    score += 6  // High bonus for exact particle match
                } else {
                    score -= 6  // Required particle doesn't match - rule fails
                }
            }
        }

        // Rule must have some verb token to be valid
        return hasVerbToken ? score : 0
    }

    /// Handles location description updates after command execution for movement and lighting changes.
    ///
    /// This method detects when the player has moved to a different location or when the lighting
    /// state has changed, and automatically describes the current location with appropriate
    /// transition messages.
    ///
    /// - Parameters:
    ///   - command: The command that was executed.
    ///   - locationBeforeCommand: The player's location before the command was executed.
    ///   - wasLitBeforeCommand: Whether the player's location was lit before the command was executed.
    func handlePostCommandLocationUpdates(
        command: Command,
        locationBeforeCommand: LocationID,
        wasLitBeforeCommand: Bool
    ) async throws {
        // Handle location description after movement or light change
        var shouldDescribe = false
        var forceFullDescription = false
        let playerLocationID = await player.location.id

        // Handle .onEnter event for new location
        if locationBeforeCommand != playerLocationID {
            // Trigger .onEnter event for the new location
            if let locationHandler = locationEventHandlers[playerLocationID] {
                if let result = try await locationHandler.handle(self, .onEnter) {
                    _ = try await processEventResult(result)
                    // onEnter events don't affect command processing flow
                }
                // Check if handler quit the game
                if shouldQuit { return }
            }
            shouldDescribe = true
        }

        // Handle lighting transition messages
        let isLitAfterCommand = await player.location.isLit

        if wasLitBeforeCommand && !isLitAfterCommand {
            // Moved from lit to dark (or light went out) - show transition message and darkness message
            await ioHandler.print(
                """
                \(messenger.nowDark())

                \(messenger.roomIsDark())
                """)
            shouldDescribe = false
            forceFullDescription = true
        } else if !wasLitBeforeCommand && isLitAfterCommand
            && locationBeforeCommand == playerLocationID
        {
            // Light came on in the same room - show the room description with full details
            shouldDescribe = true
            forceFullDescription = true
        }
        // For movement from dark to lit room, let normal movement description logic handle it (no force)

        if shouldDescribe {
            try await printCurrentLocationDescription(forceFullDescription: forceFullDescription)
        }
    }

    /// Processes the result of an action, applying state changes and printing the message.
    ///
    /// This helper is called after an `ActionHandler` (or an event handler that
    /// returns an `ActionResult`) has processed a command or event. It applies any
    /// `StateChange`s specified in the `ActionResult` to the `gameState` and prints
    /// the `ActionResult.message` to the player via the `IOHandler`.
    ///
    /// - Parameter result: The `ActionResult` returned by an action or event handler.
    /// - Throws: Re-throws errors encountered during state application.
    func processActionResult(_ result: ActionResult) async throws {
        // 1. Apply State Changes
        try applyActionResultChanges(result.changes)

        // 2. Print the result message
        if let message = result.message {
            await ioHandler.print(message)
        }

        // 3. Process any Side Effects
        try await processSideEffects(result.effects)
    }

    /// Processes an event result from item or location event handlers.
    ///
    /// This method applies any state changes and side effects, prints any message,
    /// and returns whether the event handler is yielding control back to the engine.
    ///
    /// - Parameter result: The `ActionResult` from an event handler.
    /// - Returns: `true` if the handler is yielding control (continue normal processing),
    ///           `false` if the handler fully handled the event (stop processing).
    /// - Throws: Re-throws errors encountered during state application.
    private func processEventResult(_ result: ActionResult) async throws -> Bool {
        // Apply state changes and side effects
        try applyActionResultChanges(result.changes)

        if result.effects.isNotEmpty {
            do {
                try await processSideEffects(result.effects)
            } catch {
                logError(
                    """
                    Failed to process side effects during processEventResult:
                       - \(error)
                       - Side Effects: \(result.effects)
                    """)
                throw error
            }
        }

        // Print message if present
        if let message = result.message {
            await ioHandler.print(message)
        }

        // Return whether we should yield to engine
        return result.executionFlow == .yield
    }

    /// Applies state changes from an ActionResult to the game state.
    ///
    /// This method processes an array of `StateChange` objects, handling special
    /// engine-level changes (quit/restart requests) directly and delegating
    /// game state modifications to the `gameState.apply()` method.
    ///
    /// - Parameter changes: Array of optional `StateChange` objects to apply
    /// - Throws: Re-throws any errors from `gameState.apply()` calls
    func applyActionResultChanges(_ changes: [StateChange?]) throws {
        for change in changes {
            switch change {
            case .none:
                break
            case .requestGameQuit:
                shouldQuit = true
            case .requestGameRestart:
                shouldRestart = true
            default:
                try gameState.apply(change)
            }
        }
    }

    /// Updates pronoun based on a command's direct objects.
    ///
    /// This method automatically handles pronoun updates after command execution:
    /// - No direct objects: Clears both "it" and "them" pronouns
    /// - Single direct object: Sets "it" or "them" (if plural), clears the other
    /// - Multiple direct objects: Sets "them" to all objects, "it" to the last object
    ///
    /// - Parameter command: The command that was executed.
    func updatePronounForCommand(_ command: Command) async throws {
        let directObjects = command.directObjects

        switch directObjects.count {
        case 0:
            gameState.updatePronoun(to: nil)

        case 1:
            let entity = directObjects[0].entityReference
            guard let item = directObjects[0].itemProxy else {
                gameState.updatePronoun(to: .it(entity))
                return
            }
            if await item.hasFlag(.isPlural) {
                gameState.updatePronoun(to: .them([entity]))
            } else if await item.isCharacter {
                let classification = await item.classification
                gameState.updatePronoun(
                    to: .forEntity(entity, classification: classification)
                )
            } else {
                gameState.updatePronoun(to: .it(entity))
            }

        default:
            gameState.updatePronoun(
                to: .them(directObjects.map(\.entityReference))
            )
        }
    }
}

// swiftlint:enable file_length
