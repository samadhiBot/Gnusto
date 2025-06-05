import GnustoEngine

// MARK: - Clearing Area

enum Clearing {
    // MARK: - Locations

    static let clearing = Location(
        id: .clearing,
        .name("Clearing"),
        .description("""
            You are in a clearing in the forest. The forest surrounds you
            on all sides. There appears to be a grating in the ground.
            """),
        .exits([
            .west: .to(.eastOfHouse),
            .north: .to(.gratingClearing),
        ]),
        .inherentlyLit
    )

    static let gratingClearing = Location(
        id: .gratingClearing,
        .name("Clearing"),
        .description("""
            You are in a clearing, with a forest surrounding you on all sides.
            A path leads south.
            """),
        .exits([
            .south: .to(.clearing),
        ]),
        .inherentlyLit
    )

    // MARK: - Items

    static let grating = Item(
        id: .grating,
        .name("grating"),
        .description("The grating is a large metal framework, securely fastened to the ground."),
        .synonyms("gate", "bars"),
        .in(.location(.clearing)),
        .isInvisible
    )

    static let pileOfLeaves = Item(
        id: .pileOfLeaves,
        .name("pile of leaves"),
        .description("This is a large pile of leaves."),
        .adjectives("pile", "large"),
        .synonyms("leaves", "leaf", "pile"),
        .in(.location(.clearing)),
        .isTakable
    )
}

// MARK: - Event handlers

extension Clearing {
    static let pileOfLeavesHandler = ItemEventHandler { engine, event in
        switch event {
        case .beforeTurn(let command):
            if command.verb == .move {
                // Check if grating is already revealed
                let isGratingVisible = try await engine.attribute(.isInvisible, of: .grating) != true

                if !isGratingVisible {
                    // Reveal the grating - this is the LEAVES-APPEAR functionality
                    let grating = try await engine.item(.grating)
                    let change = await engine.clearFlag(.isInvisible, on: grating)
                    return ActionResult(
                        message: "In disturbing the pile of leaves, a grating is revealed.",
                        stateChange: change
                    )
                } else {
                    return ActionResult("Done.")
                }
            }
            return nil
        case .afterTurn:
            return nil
        }
    }
}
