import GnustoEngine

print("Initializing Cloak of Darkness...\n")

let ioHandler = await ConsoleIOHandler()

await ioHandler.print("Cloak of Darkness", style: .strong)
await ioHandler.print("""
    A basic IF demonstration.
    
    Hurrying through the rainswept November night, you're glad to see the
    bright lights of the Opera House. It's surprising that there aren't more
    people about but, hey, what do you expect in a cheap demo game...?
    """)

let engine = await GameEngine(
    game: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: ioHandler
)

await engine.run()
