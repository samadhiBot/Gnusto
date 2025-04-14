import CustomDump
import Testing

@testable import Gnusto

@Suite("Command Parser Tests")
struct CommandParserTests {
    let parser: CommandParser

    init() throws {
        parser = try CommandParser()
    }

    // MARK: - Helpers

    // Helper to get the UserInput from a parsed Action
    func getUserInput(
        from action: Action,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> UserInput {
        guard case .command(let userInput) = action else {
            throw TestFailure("Expected .command action, got \(action)")
        }
        print("🎾", userInput)
        return userInput
    }

    // MARK: - Basic Commands

    @Test("Look command")
    func lookCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("look")),
            UserInput(verb: .look, rawInput: "look")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("l")),
            UserInput(verb: "l", rawInput: "l") // Abbreviations use direct init
        )
    }

    @Test("Examine command")
    func examineCommand() throws {
        expectNoDifference(
            try getUserInput(
                from: parser.parse("examine chest")
            ),
            UserInput(
                verb: .examine,
                directObject: "chest",
                rawInput: "examine chest"
            )
        )

        expectNoDifference(
            try getUserInput(
                from: parser.parse("x wooden chest") // Assumes 'x' is synonym, parser handles modifiers
            ),
            UserInput(
                verb: "x",
                directObject: "chest",
                directObjectModifiers: "wooden",
                rawInput: "x wooden chest"
            )
        )

        expectNoDifference(
            try getUserInput(
                from: parser.parse("examine the box") // Assumes parser removes "the"
            ),
            UserInput(
                verb: .examine,
                directObject: "box",
                rawInput: "examine the box"
            )
        )
    }

    @Test("Inventory command")
    func inventoryCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("inventory")),
            UserInput(verb: .inventory, rawInput: "inventory")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("i")),
            UserInput(verb: "i", rawInput: "i")
        )
    }

    @Test("Quit command")
    func quitCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("quit")),
            UserInput(verb: .quit, rawInput: "quit")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("q")),
            UserInput(verb: "q", rawInput: "q")
        )
    }

    @Test("Wait command")
    func waitCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("wait")),
            UserInput(verb: .wait, rawInput: "wait")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("z")),
            UserInput(verb: "z", rawInput: "z")
        )
    }

    @Test("Help command")
    func helpCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("help")),
            UserInput(verb: .help, rawInput: "help")
        )
    }

    @Test("Version command")
    func versionCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("version")),
            UserInput(verb: .version, rawInput: "version")
        )
    }

    // MARK: - Movement Commands

    @Test("Directional movement")
    func directionalMovement() throws {
        // Direct directions are often handled as verbs themselves
        expectNoDifference(
            try getUserInput(from: parser.parse("north")),
            UserInput(verb: .north, rawInput: "north")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("go north")),
            UserInput(
                verb: .go,
                prepositions: "north",
                rawInput: "go north"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("n")),
            UserInput(verb: "n", rawInput: "n")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("south")),
            UserInput(verb: .south, rawInput: "south")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("walk east")),
            UserInput(
                verb: .walk,
                prepositions: "east",
                rawInput: "walk east"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("nw")),
            UserInput(verb: "nw", rawInput: "nw")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("go up")),
            UserInput(
                verb: .go,
                prepositions: "up",
                rawInput: "go up"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("d")),
            UserInput(verb: "d", rawInput: "d") // Assumes parser maps d -> down
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("in")),
            UserInput(verb: "in", rawInput: "in")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("go out")),
            UserInput(
                verb: .go,
                prepositions: "out",
                rawInput: "go out"
            )
        )
    }

     // MARK: - Object Manipulation

    @Test("Take command")
    func takeCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("take the lantern")),
            UserInput(
                verb: .take,
                directObject: "lantern",
                rawInput: "take the lantern"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("get lamp")),
            UserInput(
                verb: .get,
                directObject: "lamp",
                rawInput: "get lamp"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("pick up the brass lantern")),
            UserInput(
                verb: .pick,
                directObject: "lantern",
                directObjectModifiers: "brass",
                prepositions: "up",
                rawInput: "pick up the brass lantern"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("grab sword")),
            UserInput(
                verb: .grab,
                directObject: "sword",
                rawInput: "grab sword"
            )
        )
    }

    @Test("Drop command")
    func dropCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("drop key")),
            UserInput(
                verb: .drop,
                directObject: "key",
                rawInput: "drop key"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("put down the rusty key")),
            UserInput(
                verb: .put,
                directObject: "key",
                directObjectModifiers: "rusty",
                prepositions: "down",
                rawInput: "put down the rusty key"
            )
        )
    }

    @Test("PutIn command")
    func putInCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("put key in chest")),
            UserInput(
                verb: .put,
                directObject: "key",
                prepositions: "in",
                indirectObject: "chest",
                rawInput: "put key in chest"
            )
        )

        expectNoDifference(
            try getUserInput(
                from: parser.parse("put the rusty key into the wooden chest")
            ),
            UserInput(
                verb: .put,
                directObject: "key",
                directObjectModifiers: "rusty",
                prepositions: "into",
                indirectObject: "chest",
                indirectObjectModifiers: "wooden",
                rawInput: "put the rusty key into the wooden chest"
            )
        )

        expectNoDifference(
            try getUserInput(
                from: parser.parse("insert key in chest") // Synonym for put
            ),
            UserInput(
                verb: .insert,
                directObject: "key",
                prepositions: "in",
                indirectObject: "chest",
                rawInput: "insert key in chest"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("put key inside box")),
            UserInput(
                verb: .put,
                directObject: "key",
                prepositions: "inside",
                indirectObject: "box",
                rawInput: "put key inside box"
            )
        )
    }

    // MARK: - Container/Door Interaction

    @Test("Open command")
    func openCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("open chest")),
            UserInput(
                verb: .open,
                directObject: "chest",
                rawInput: "open chest"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("open the wooden chest")),
            UserInput(
                verb: .open,
                directObject: "chest",
                directObjectModifiers: "wooden",
                rawInput: "open the wooden chest"
            )
        )
    }

    @Test("Close command")
    func closeCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("close chest")),
            UserInput(
                verb: .close,
                directObject: "chest",
                rawInput: "close chest"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("close the box")),
            UserInput(
                verb: .close,
                directObject: "box",
                rawInput: "close the box"
            )
        )
    }

    @Test("Lock command")
    func lockCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("lock chest")),
            UserInput(
                verb: .lock,
                directObject: "chest",
                rawInput: "lock chest"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("lock chest with key")),
            UserInput(
                verb: .lock,
                directObject: "chest",
                prepositions: "with",
                indirectObject: "key",
                rawInput: "lock chest with key"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("lock wooden chest using rusty key")),
            UserInput(
                verb: .lock,
                directObject: "chest",
                directObjectModifiers: "wooden",
                prepositions: "using",
                indirectObject: "key",
                indirectObjectModifiers: "rusty",
                rawInput: "lock wooden chest using rusty key"
            )
        )
    }

    @Test("Unlock command")
    func unlockCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("unlock chest")),
            UserInput(
                verb: .unlock,
                directObject: "chest",
                rawInput: "unlock chest"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("unlock chest with key")),
            UserInput(
                verb: .unlock,
                directObject: "chest",
                prepositions: "with",
                indirectObject: "key",
                rawInput: "unlock chest with key"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("unlock the box with the key")),
            UserInput(
                verb: .unlock,
                directObject: "box",
                prepositions: "with",
                indirectObject: "key",
                rawInput: "unlock the box with the key"
            )
        )
    }

    // MARK: - Device Interaction

    @Test("Turn On command")
    func turnOnCommand() throws {
        expectNoDifference(
            try getUserInput(
                from: parser.parse("turn on lantern")
            ),
            UserInput(
                verb: "turn",
                directObject: "lantern",
                prepositions: "on",
                rawInput: "turn on lantern"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("light lamp")),
            UserInput(
                verb: "light",
                directObject: "lamp",
                rawInput: "light lamp"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("switch on the brass lantern")),
            UserInput(
                verb: "switch",
                directObject: "lantern",
                directObjectModifiers: "brass",
                prepositions: "on",
                rawInput: "switch on the brass lantern"
            )
        )
    }

    @Test("Turn Off command")
    func turnOffCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("turn off lantern")),
            UserInput(
                verb: "turn",
                directObject: "lantern",
                prepositions: "off",
                rawInput: "turn off lantern"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("extinguish lamp")),
            UserInput(
                verb: "extinguish",
                directObject: "lamp",
                rawInput: "extinguish lamp"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("switch off the light")),
            UserInput(
                verb: "switch",
                directObject: "light",
                prepositions: "off",
                rawInput: "switch off the light"
            )
        )
    }

    // MARK: - Misc Actions

    @Test("Read command")
    func readCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("read scroll")),
            UserInput(
                verb: .read,
                directObject: "scroll",
                rawInput: "read scroll"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("read the ancient scroll")),
            UserInput(
                verb: .read,
                directObject: "scroll",
                directObjectModifiers: "ancient",
                rawInput: "read the ancient scroll"
            )
        )
    }

    @Test("Drink command")
    func drinkCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("drink potion")),
            UserInput(
                verb: .drink,
                directObject: "potion",
                rawInput: "drink potion"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("drink the blue potion")),
            UserInput(
                verb: .drink,
                directObject: "potion",
                directObjectModifiers: "blue",
                rawInput: "drink the blue potion"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("swallow potion")),
            UserInput(
                verb: .swallow,
                directObject: "potion",
                rawInput: "swallow potion"
            )
        )
    }

    @Test("Talk command")
    func talkCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("talk to troll")),
            UserInput(
                verb: .talk,
                directObject: "troll",
                prepositions: "to",
                rawInput: "talk to troll"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("talk grumpy troll")),
            // No preposition
            UserInput(
                verb: .talk,
                directObject: "troll",
                directObjectModifiers: "grumpy",
                rawInput: "talk grumpy troll"
            )
        )
    }

    @Test("Toss/Throw command")
    func tossThrowCommand() throws {
        // Assuming toss/throw map to the same underlying verb/handler
        expectNoDifference(
            try getUserInput(from: parser.parse("toss key")),
            UserInput(
                verb: .toss,
                directObject: "key",
                rawInput: "toss key"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("throw the rusty key")),
            UserInput(
                verb: .`throw`,
                directObject: "key",
                directObjectModifiers: "rusty",
                rawInput: "throw the rusty key"
            )
        )
    }

    @Test("Attack command")
    func attackCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("attack grumpy troll")),
            UserInput(
                verb: .attack,
                directObject: "troll",
                directObjectModifiers: "grumpy",
                rawInput: "attack grumpy troll"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("hit troll")),
            UserInput(
                verb: .hit,
                directObject: "troll",
                rawInput: "hit troll"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("attack troll with sword")),
            UserInput(
                verb: .attack,
                directObject: "troll",
                prepositions: "with",
                indirectObject: "sword",
                rawInput: "attack troll with sword"
            )
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("attack troll using iron sword")),
            UserInput(
                verb: .attack,
                directObject: "troll",
                prepositions: "using",
                indirectObject: "sword",
                indirectObjectModifiers: "iron",
                rawInput: "attack troll using iron sword"
            )
        )
    }

    // MARK: - Parser Edge Cases

    @Test("Unknown command")
    func unknownCommand() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("xyzzy")),
            UserInput(verb: "xyzzy", rawInput: "xyzzy")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("frobozz the chest")),
            UserInput(
                verb: "frobozz",
                directObject: "chest",
                rawInput: "frobozz the chest"
            )
        )
    }

    @Test("Command without object")
    func commandWithoutObject() throws {
        expectNoDifference(
            try getUserInput(from: parser.parse("take")),
            UserInput(verb: .take, rawInput: "take")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("open")),
            UserInput(verb: .open, rawInput: "open")
        )
    }

    @Test("Command with indirect object but no preposition")
    func commandWithIndirectObjectNoPreposition() throws {
         // Nitfol likely parses "chest key" as the direct object without a preposition
         expectNoDifference(
            try getUserInput(from: parser.parse("lock chest key")),
            UserInput(
                verb: .lock,
                directObject: "key",
                directObjectModifiers: "chest",
                rawInput: "lock chest key"
            ) // Updated based on likely Nitfol behavior
         )
    }

    @Test("Empty input")
    func emptyInput() throws {
        // Nitfol might return an action with nil verb for empty/invalid input
        expectNoDifference(
            try getUserInput(from: parser.parse("")),
            UserInput(verb: nil, rawInput: "")
        )

        expectNoDifference(
            try getUserInput(from: parser.parse("   ")),
            UserInput(verb: nil, rawInput: "   ")
        )
    }

    @Test("Stop words only")
    func inputStopWords() throws {
        // Similar to empty input, likely results in nil verb
        expectNoDifference(
            try getUserInput(from: parser.parse("the a an")),
            UserInput(verb: nil, directObject: "an", rawInput: "the a an")
        )
    }
}
