import GnustoEngine

print("Initializing Cloak of Darkness...\n")

let engine = GameEngine(
    game: CloakOfDarkness(),
    parser: StandardParser(),
    ioHandler: await ConsoleIOHandler()
)

await engine.run()

print("\nThank you for playing Cloak of Darkness!")
