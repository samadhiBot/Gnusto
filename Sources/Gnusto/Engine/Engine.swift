import Foundation

/// The central coordinator for the game.
public class Engine {
    /// The game definition.
    private let game: Game

    /// Input parser for commands.
    private let parser: CommandParser

    /// Command registry holding default and game-specific handlers.
    private let commandRegistry: CommandRegistry

    /// Action dispatcher.
    private let dispatcher: ActionDispatcher

    /// Renderer for game output.
    private let renderer: Renderer

    /// The current state of the game world.
    private(set) var world: World

    /// Initialize a new game engine.
    /// - Parameters:
    ///   - game: The game definition.
    ///   - renderer: The renderer for output.
    public init(game: Game, renderer: Renderer) throws {
        self.game = game
        self.parser = try CommandParser()
        self.renderer = renderer

        // Create and configure the command registry
        let registry = CommandRegistry()
        registry.registerDefaultHandlers() // Register engine default handlers
        // TODO: Allow game to register its own handlers/overrides on the registry
        self.commandRegistry = registry

        // Initialize the dispatcher with the configured registry
        self.dispatcher = ActionDispatcher(commandRegistry: self.commandRegistry)

        // Create the world from the game definition
        self.world = try game.createWorld()

        // Register custom actions (This mechanism might merge with CommandRegistry later)
        for actionDef in game.defineCustomActions() {
            dispatcher.registerCustomHandler(actionDef.verb) { context, world in
                actionDef.handler(context)
            }
        }

        // Register event handlers from the game
        for eventDef in game.defineEventHandlers() {
            dispatcher.registerEventHandler(eventDef.id.rawValue) { world in
                eventDef.handler(world)
            }
        }
    }

    /// Start the game.
    public func start(enterGameLoop: Bool = true) throws {
        // Show welcome text
        renderer.render(.showText(game.welcomeText))
        renderer.render(.showText(game.versionInfo))
        renderer.render(.showText("Type 'help' for a list of commands."))

        // Process initial look command by parsing "look"
        processAction(parser.parse("look"))

        // Main game loop
        if enterGameLoop {
            gameLoop()
        }
    }

    /// The main game loop.
    private func gameLoop() {
        while world.state == .running {
            // Get input from the player
            if let input = renderer.getInput(prompt: "> ") {
                // Parse the input into an action
                let action = parser.parse(input)

                // Process the action
                processAction(action)

                // Process any events triggered this turn
                processEvents()

                // Update the status line
                updateStatusLine()
            }
        }

        // Handle game over state
        if let message = world.state.message {
            renderer.render(.showText(message))
        }
        renderer.render(.endGame)
    }

    /// Process a game action.
    /// - Parameter action: The action to process.
    public func processAction(_ action: Action) {
        // Dispatch the action to get effects
        let effects = dispatcher.dispatch(action, in: world)

        // Render each effect
        for effect in effects {
            renderer.render(effect)
        }

        // Update move count for command actions
        // (Removed the isMeta check as ParsedCommand doesn't have it)
        // FIXME: meta commands should not increment moves
        if case .command = action {
            incrementMoves()
        }
    }

    /// Process any events triggered this turn.
    private func processEvents() {
        let effects = dispatcher.processTurnEvents(in: world)

        // Render each effect
        for effect in effects {
            renderer.render(effect)
        }
    }

    /// Updates the status line with current game information.
    private func updateStatusLine() {
        guard let playerComponent = world.player.find(PlayerComponent.self),
            let location = world.playerLocation,
            let descComponent = location.find(DescriptionComponent.self)
        else {
            return
        }

        renderer.render(
            .updateStatusLine(
                location: descComponent.name,
                score: playerComponent.score,
                moves: playerComponent.moves
            )
        )
    }

    /// Increments the player's move count.
    private func incrementMoves() {
        world.modifyPlayer { player in
            player.modify(PlayerComponent.self) {
                $0.moves += 1
            }
        }
    }
}
