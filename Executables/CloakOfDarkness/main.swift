import GnustoEngine

let engine = await GameEngine(
    game: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
