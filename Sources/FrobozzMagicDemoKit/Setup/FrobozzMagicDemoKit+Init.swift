import Foundation // Needed for print in setupLanternTimer call, might move later
import GnustoEngine

// Placeholders removed, assuming actual files exist now.

// MARK: - Initialization Extension
@MainActor
extension FrobozzMagicDemoKit {
    /// Creates a new example game with all the necessary components set up.
    /// - Parameter customIOHandler: An optional custom IO handler. If nil, a ConsoleIOHandler is used.
    init(customIOHandler: IOHandler? = nil) async {
        // Set up the game data
        // We assume GameDataSetup is available and provides the necessary static method
        let (initialState, registry) = await GameDataSetup.createGameData()

        // Create the parser
        let parser = StandardParser()

        // Create or use the provided IO handler
        let resolvedIOHandler: IOHandler
        if let customIOHandler = customIOHandler {
            resolvedIOHandler = customIOHandler
        } else {
            resolvedIOHandler = await ConsoleIOHandler()
        }
        self.ioHandler = resolvedIOHandler

        // Create a scope resolver
        let scopeResolver = ScopeResolver()

        // Create the engine with the initial components
        engine = GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: resolvedIOHandler,
            scopeResolver: scopeResolver,
            registry: registry,
            onEnterRoom: Hooks.onEnterRoom, // Reference actual Hooks
            beforeTurn: Hooks.beforeEachTurn, // Reference actual Hooks
            onExamineItem: Hooks.onExamineItem // Reference actual Hooks
            // Note: Other hooks might be added here later if needed
        )

        // Set up the lantern timer and initial weather state
        // References actual Components.Lantern
        await Components.Lantern.setupLanternTimer(engine: engine)

        // Display an introduction message
        await ioHandler.print("Welcome to the Gnusto Example Adventure!", style: .strong)
        await ioHandler.print(
            """
            This small adventure demonstrates various features of the Gnusto Engine.
            Type 'help' for hints on what to try.
            """,
            style: .emphasis
        )
        await ioHandler.print("", style: .normal)
    }
}
