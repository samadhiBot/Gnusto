import GnustoEngine

struct LocalGlobals {
    let board = Item(
        id: .board
    )

    let bodies = Item(.bodies)
        .name("pile of bodies")
        .synonyms("bodies", "body", "remains", "pile")
        .adjectives("mangled")
        .omitDescription
        .requiresTryTake
        // Note: Has action handler BODY-FUNCTION

    let globalWater = Item(
        id: .globalWater
    )

    let stairs = Item(
        id: .stairs
    )
}
