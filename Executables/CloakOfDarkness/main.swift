import GnustoEngine

let engine = await GameEngine(
    blueprint: CloakOfDarkness(),
    player: Player(in: .foyer),
    globalState: [
        .barMessageDisturbances: 0
    ],
    parser: StandardParser(),
    ioHandler: ConsoleIOHandler()
)

await engine.run()
