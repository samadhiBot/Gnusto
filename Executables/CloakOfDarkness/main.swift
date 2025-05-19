import GnustoEngine

let engine = await GameEngine(
    blueprint: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
