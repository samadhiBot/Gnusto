import GnustoEngine

struct Items: ItemDefinitions {
    let cloak = Item(
        id: "cloak",
        name: "cloak",
        adjectives: "handsome", "velvet",
        properties: .takable, .wearable, .worn,
        parent: .player
    )

    let hook = Item(
        id: "hook",
        name: "hook",
        adjectives: "brass",
        synonyms: "peg",
        properties: .surface,
        parent: .location("cloakroom")
    )

    let message = Item(
        id: "message",
        name: "message",
        properties: .ndesc, .read,
        parent: .location("bar"),
        readableText: "You have won!"
    )

    let playerItem = Item(
        id: "player",
        name: "yourself",
        synonyms: "me", "myself",
        properties: .person
    )

}
