import GnustoEngine

struct AutoWiringTestGame: GameBlueprint {
    let constants = GameConstants(
        storyTitle: "Auto-Wiring Test Game",
        introduction: "Testing auto-wiring plugin scenarios...",
        release: "1",
        maximumScore: 100
    )

    var player: Player {
        Player(in: .livingRoom)
    }
}
