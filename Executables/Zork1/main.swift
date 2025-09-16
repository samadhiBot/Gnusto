import GnustoEngine

let engine = await GameEngine(
    blueprint: Zork1(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler(
        markdownParser: MarkdownParser(columns: 64)
    )
)

await engine.run()
