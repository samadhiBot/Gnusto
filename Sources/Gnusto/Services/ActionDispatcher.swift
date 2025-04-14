import Foundation

/// Processes game actions and produces effects.
public class ActionDispatcher {
    /// The registry used to find handlers for parsed commands.
    private let commandRegistry: CommandRegistry

    /// Handlers for custom actions defined by the game
    private var customHandlers: [String: (ActionContext, World) -> [Effect]] = [:]

    /// Handlers for events
    private var eventHandlers: [String: (World) -> [Effect]] = [:]

    /// Initializes the dispatcher with required services.
    ///
    /// - Parameter commandRegistry: The registry for standard command handlers.
    public init(commandRegistry: CommandRegistry) {
        self.commandRegistry = commandRegistry
    }

    /// Dispatches an action and produces effects
    public func dispatch(_ action: Action, in world: World) -> [Effect] {
        // Declare variables needed after the switch here
        var handlerEntry: CommandRegistry.HandlerEntry? = nil
        var commandCanonicalID: VerbID? = nil // Store ID for implicit look check
        var wasBlockedByDarkness = false // Flag for darkness block

        // Check for beforeAction hook in current room
        if let location = world.playerLocation,
           let hooksComponent = location.find(RoomHooksComponent.self),
           let beforeActionHook = hooksComponent.beforeAction,
           let effects = beforeActionHook(action, world)
        {
            return effects // Hook handled the action
        }

        // Get base effects from processing the action
        var baseEffects: [Effect] = [] // Initialize to empty
        var isDark = false
        var worksInDarkness = false // Store the flag from HandlerEntry

        switch action {
        case .command(let userInput):
            // --- Find Handler Entry and Determine Darkness Properties ---
            var matchedPrepositionForContext: String? = nil // For creating the CommandContext later

            if let verb = userInput.verb {
                // Try phrase with first preposition
                if let firstPrep = userInput.prepositions.first {
                    let phraseWithPrep = VerbPhrase(verb: verb.rawValue, preposition: firstPrep)
                    if let entry = commandRegistry.handlerEntry(for: phraseWithPrep) {
                        handlerEntry = entry
                        matchedPrepositionForContext = firstPrep
                    }
                }
                // Try phrase with verb only if no preposition match
                if handlerEntry == nil {
                    let phraseNoPrep = VerbPhrase(verb: verb.rawValue)
                    handlerEntry = commandRegistry.handlerEntry(for: phraseNoPrep)
                }

                // Store results from the found entry (if any)
                commandCanonicalID = handlerEntry?.canonicalVerbID
                worksInDarkness = handlerEntry?.worksInDarkness ?? false // Default to false if no handler
            }

            // --- Quit Check --- (Re-check using the now determined canonical ID)
            if commandCanonicalID == .quit, let entry = handlerEntry {
                // Create context using the matched preposition info
                let contextUserInput = Self.createContextUserInput(
                    originalInput: userInput,
                    matchedPreposition: matchedPrepositionForContext
                )
                let context = CommandContext(
                    userInput: contextUserInput,
                    world: world,
                    canonicalVerbID: entry.canonicalVerbID
                )
                if let quitEffects = entry.handler(context) {
                    return quitEffects // Quit handler sets state, bypass further processing
                }
            }

            var handledByObjectResponse = false // Flag for object response
            // Object-specific responses (proceed only if not quit)
            if let objectIDString = userInput.directObject,
               let object = world.find(Object.ID(objectIDString)),
               let responseComponent = object.find(ResponseComponent.self),
               responseComponent.hasResponse(for: userInput)
            {
                if let handler = responseComponent.getResponse(for: userInput) {
                    let result = handler(world, userInput)
                    result.updateState(world)
                    // Assume object responses always succeed if found and return effects
                    baseEffects = result.effects
                    commandCanonicalID = userInput.verb // Use raw verb for obj response ID? Or try lookup?
                    handledByObjectResponse = true
                    // No break needed, logic below will skip if handledByObjectResponse is true
                }
            }

            // Proceed only if not handled by object response
            if !handledByObjectResponse {
                // --- Try Registry Handler First ---
                baseEffects = processCommandUsingRegistry(
                    userInput,
                    in: world,
                    handlerEntry: handlerEntry,
                    matchedPreposition: matchedPrepositionForContext
                )

                // --- Handle Failures (including darkness) ---
                if baseEffects.isEmpty { // Handler failed or didn't exist
                    // Determine if it's currently dark
                    isDark = world.playerLocation.map { !world.isIlluminated($0.id) } ?? true

                    if isDark && !(handlerEntry?.worksInDarkness ?? false) {
                        // Failure was in the dark, and the command doesn't work in the dark.
                        // Use the generic dark message.
                        baseEffects = handleDarkRoomAction(userInput, in: world)
                        wasBlockedByDarkness = true // Mark as blocked by darkness itself
                    } else {
                        // Failure wasn't due to darkness (either lit room, or command works in dark).
                        // Use standard failure messages.
                        if let verb = userInput.verb {
                            if handlerEntry != nil {
                                // Handler existed but failed (returned nil/empty)
                                let verbString = commandCanonicalID?.rawValue ?? verb.rawValue
                                baseEffects = [.showText("You can't seem to '\(verbString)' right now.")]
                            } else {
                                // No handler found
                                let verbString = verb.rawValue
                                baseEffects = [.showText("I don't know how to '\(verbString)'.")]
                            }
                        } else {
                            // No verb parsed
                            baseEffects = [.showText("I'm not sure what you want to do.")]
                        }
                    }
                } else {
                    // Handler succeeded, clear darkness flag if it was set prematurely
                    wasBlockedByDarkness = false
                }
            }

        case .event(let eventId):
            baseEffects = processEvent(eventId, in: world)
        case .custom(let verb, let context):
            if let handler = customHandlers[verb] {
                baseEffects = handler(context, world)
            } else {
                baseEffects = [.showText("I don't know how to do that.")]
            }
            commandCanonicalID = VerbID(verb)
        case .gameOver(let endState):
            world.updateState(to: endState)
            var gameOverEffects: [Effect] = []
            if let message = endState.message {
                gameOverEffects.append(.showText(message))
            }
            gameOverEffects.append(.endGame)
            baseEffects = gameOverEffects
        case .wait(let turns):
            var waitEffects: [Effect] = [.showText("Time passes...")]
            for _ in 0..<turns {
                let eventEffects = processTurnEvents(in: world)
                waitEffects.append(contentsOf: eventEffects)
            }
            baseEffects = waitEffects
        }

        // baseEffects is now guaranteed non-nil
        var combinedEffects = baseEffects

        // Check for afterAction hook (only if not blocked by darkness?)
        if !wasBlockedByDarkness, let location = world.playerLocation,
           let hooksComponent = location.find(RoomHooksComponent.self),
           let afterActionHook = hooksComponent.afterAction
        {
            let additionalEffects = afterActionHook(action, world)
            combinedEffects += additionalEffects
        }

        // --- New Implicit Look Logic (Triggered by Effect) ---
        if combinedEffects.contains(.triggerImplicitLook) {
            // Remove the trigger effect itself
            combinedEffects.removeAll { $0 == .triggerImplicitLook }

            // Determine if it's dark *now* (state might have changed)
            let isCurrentlyDark = world.playerLocation.map { !world.isIlluminated($0.id) } ?? true

            // Only perform the look if it's not dark
            if !isCurrentlyDark, let playerLoc = world.playerLocation {
                // Call LookHandler to get the description effects
                let lookActionInput = UserInput(verb: .look, rawInput: "look")
                let lookContext = CommandContext(
                    userInput: lookActionInput,
                    world: world, // Use the potentially modified world state
                    canonicalVerbID: .look
                )
                if let lookEffects = LookHandler.handle(context: lookContext) {
                    combinedEffects += lookEffects
                }
            }
        }

        return combinedEffects
    }

    /// Creates the `UserInput` to be passed into a `CommandContext`.
    ///
    /// If a preposition was matched during handler lookup, it's removed from the
    /// preposition list so the handler doesn't see it.
    private static func createContextUserInput(
        originalInput: UserInput,
        matchedPreposition: String?
    ) -> UserInput {
        guard let prepToRemove = matchedPreposition else {
            // No preposition matched, use original input
            return originalInput
        }

        // Create a new UserInput with the preposition removed
        let updatedPrepositions = originalInput.prepositions.filter { $0 != prepToRemove }
        return UserInput(
            verb: originalInput.verb,
            directObject: originalInput.directObject,
            directObjectModifiers: originalInput.directObjectModifiers,
            prepositions: updatedPrepositions, // Use the filtered list
            indirectObject: originalInput.indirectObject,
            indirectObjectModifiers: originalInput.indirectObjectModifiers,
            rawInput: originalInput.rawInput
        )
    }

    /// Processes a command by executing its handler using the pre-determined `HandlerEntry`.
    /// Returns effects if the command was handled successfully, [] otherwise.
    private func processCommandUsingRegistry(
        _ command: UserInput,
        in world: World,
        handlerEntry: CommandRegistry.HandlerEntry?,
        matchedPreposition: String?
    ) -> [Effect] {
        guard let entry = handlerEntry else {
            // No handler registered or found earlier
            return []
        }

        // Prepare the context using the helper
        let contextUserInput = Self.createContextUserInput(
            originalInput: command,
            matchedPreposition: matchedPreposition
        )

        let context = CommandContext(
            userInput: contextUserInput,
            world: world,
            canonicalVerbID: entry.canonicalVerbID
        )

        // Execute the handler
        if let effects = entry.handler(context), !effects.isEmpty {
            // Success with effects
            return effects
        } else {
            // Handler found but returned nil OR empty array (failure/no effect)
            return []
        }
    }

    // Fallback for actions attempted in darkness
    // Now correctly receives UserInput
    private func handleDarkRoomAction(_ command: UserInput, in world: World) -> [Effect] {
        return [.showText("It's too dark to see! You might need a light source.")]
    }

    /// Processes a scheduled event
    private func processEvent(_ eventId: String, in world: World) -> [Effect] {
        // Look for a specific event handler
        if let handler = eventHandlers[eventId] {
            return handler(world)
        }

        // Default handling for different event types
        switch eventId {
            // Add default event handlers here
        default:
            return [.showText("Event \"\(eventId)\" occurred but no handler was found.")]
        }
    }

    /// Process events for the current turn
    public func processTurnEvents(in world: World) -> [Effect] {
        // Get events due for this turn
        let dueEvents = world.processEvents()

        // Process each event and collect effects
        var effects: [Effect] = []
        for eventId in dueEvents {
            let eventEffects = processEvent(eventId.rawValue, in: world)
            effects.append(contentsOf: eventEffects)
        }

        return effects
    }

    /// Registers a custom action handler
    public func registerCustomHandler(
        _ verb: String,
        handler: @escaping (ActionContext, World) -> [Effect]
    ) {
        customHandlers[verb] = handler
    }

    /// Registers an event handler
    public func registerEventHandler(
        _ eventId: String,
        handler: @escaping (World) -> [Effect]
    ) {
        eventHandlers[eventId] = handler
    }
}
