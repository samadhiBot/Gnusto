import GnustoEngine

let engine = await GameEngine(
    blueprint: Zork1(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
