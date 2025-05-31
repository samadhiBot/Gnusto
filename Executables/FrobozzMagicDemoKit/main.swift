import GnustoEngine

let engine = await GameEngine(
    blueprint: FrobozzMagicDemoKit(),
    player: Player(in: .yourCottage),
    globalState: [
        .gnustoEscaped: false
    ],
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
