import GnustoEngine

let engine = await GameEngine(
    blueprint: FrobozzMagicDemoKit(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
