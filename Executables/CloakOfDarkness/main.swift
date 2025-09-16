import GnustoEngine

let engine = await GameEngine(
    blueprint: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler(
        markdownParser: MarkdownParser(columns: 64)
    )
)

await engine.run()
