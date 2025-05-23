import GnustoEngine

/// The Frobozz Magic Demo Kit - A comprehensive demonstration of the Gnusto Interactive Fiction Engine.
///
/// This demo showcases engine features through a three-act narrative about the accidental discovery
/// of the GNUSTO spell. Act I demonstrates core mechanics, while Acts II and III will show
/// progressively more advanced features.
///
/// ## Learning Path
/// - **New developers**: Focus on Act I for basics
/// - **Intermediate developers**: Study the progression to Act II
/// - **Advanced developers**: Examine the complete integration in Act III
///
/// ## Current Implementation Status
/// - ✅ **Act I**: Core mechanics and basic puzzle solving
/// - ⏳ **Act II**: Time-based events and custom behaviors (planned)
/// - ⏳ **Act III**: Complex systems integration (planned)
struct FrobozzMagicDemoKit: GameBlueprint {

    // MARK: - Game Metadata

    var constants: GameConstants {
        GameConstants(
            storyTitle: "The Frobozz Magic Demo Kit",
            introduction: """
                769 GUE. You are a neighbor of a little-known thaumaturge named Berzio.

                Like all of the nearby neighbors, you pack up some food about once a week,
                and drop it off at Berzio's front door. In return, a pleasant aura of magic
                pervades your mile of the winding country road, keeping the hedges in check
                and the flowers in bloom.

                On this day you leave your house with basket in hand, containing a warm
                sourdough boule, a crock of fresh butter and a jar of cherry preserves.
                Your other hand grips a glass jug filled with freshly squeezed blackberry lemonade.
                """,
            release: "Demo v0.1.0",
            maximumScore: 100
        )
    }

    // MARK: - Game State

    var state: GameState {
        // Combine all areas for Act I
        let act1 = Act1Area()

        // Build vocabulary from all items and standard verbs
        let vocabulary = Vocabulary.build(
            items: Act1Area.items,
            verbs: [] // Using engine defaults for now
        )

        return GameState(
            locations: Act1Area.locations,
            items: Act1Area.items,
            player: Player(in: "yourHouse"),
            vocabulary: vocabulary,
            globalState: [
                // Global flags for Act I story progression
                "gnustoEscaped": .bool(false),
                "lemonadeOnHead": .bool(false),
                "basketPutDown": .bool(false),
                "gnustoCaught": .bool(false)
            ]
        )
    }

    // MARK: - Event Handlers

    var itemEventHandlers: [ItemID: ItemEventHandler] {
        Act1Area.itemEventHandlers
    }

    var locationEventHandlers: [LocationID: LocationEventHandler] {
        Act1Area.locationEventHandlers
    }

    // MARK: - Game Hooks

//    var onEnterRoom: @Sendable (GameEngine, LocationID) async -> Bool {
//        { engine, locationID in
//            // Special handling for key story moments
//            switch locationID.rawValue {
//            case "berziosGate":
//                // This is where Gnusto escapes!
//                let gnustoEscaped = await engine.isFlagSet(.gnustoEscaped)
//                if !gnustoEscaped {
//                    await engine.setFlag(.gnustoEscaped)
//
//                    // Move Gnusto from nowhere to the gate area
//                    try? await engine.move(<#T##item: Item##Item#>, to: <#T##ParentEntity#>)
//                        .moveItem("gnustoDog", to: .location("berziosGate"))
//
//                    await engine.ioHandler.print("""
//
//                        But before you can take a step into Berzio's garden, his little dog Gnusto
//                        slips out, dashing between your ankles and into the lane. Overjoyed to have
//                        company, she skitters about wriggling this way and that.
//                        """)
//
//                    return false // Let normal room description proceed
//                }
//                return false
//
//            default:
//                return false
//            }
//        }
//    }

    var beforeTurn: @Sendable (GameEngine, Command) async -> Bool {
        { engine, command in
            // Check for the classic parser confusion with "gnusto"
            if command.rawInput.lowercased().contains("gnusto") &&
               command.verb == .unknown {
                await engine.ioHandler.print("What do you want to gnusto?")
                return true // Command handled
            }

            return false
        }
    }
}

// MARK: - Supporting Types

extension GlobalID {
    static let gnustoEscaped: GlobalID = "gnustoEscaped"
}

extension LocationID {
    static let yourHouse: LocationID = "yourHouse"
    static let stoneBridge: LocationID = "stoneBridge"
    static let countryRoad: LocationID = "countryRoad"
    static let berziosGate: LocationID = "berziosGate"
    static let berziosGarden: LocationID = "berziosGarden"
}

extension ItemID {
    static let basket: ItemID = "basket"
    static let sourdoughBoule: ItemID = "sourdoughBoule"
    static let butterCrock: ItemID = "butterCrock"
    static let preserveJar: ItemID = "preserveJar"
    static let lemonade: ItemID = "lemonade"
    static let gnustoDog: ItemID = "gnustoDog"
}
