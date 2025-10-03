import GnustoEngine

let engine = await GameEngine(
    blueprint: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler(
        markdownParser: MarkdownParser(columns: 69)
    )
)

await engine.run()
