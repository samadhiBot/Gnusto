import Foundation
import Gnusto

/// A simple test game to verify Gnusto engine functionality
struct TestGame: Game {
    let welcomeText = """
        TEST ADVENTURE
        A simple test game for the Gnusto engine.

        You are standing in a small room. There's a door to the north.
        """

    let versionInfo = "Test Adventure v1.0"

    func createWorld() throws -> World {
        let world = World(
            player: .player(
                name: "Adventurer",
                description: "An eager adventurer ready for excitement.",
                location: "startRoom"
            )
        )

        // Rooms
        world.add(
            .room(
                id: "startRoom",
                name: "Starting Room",
                description: "This is where your adventure begins. A small, cozy room with wooden walls and a comfortable feel.",
                isLit: false
            ),
            .room(
                id: "northRoom",
                name: "North Room",
                description: "A slightly larger room with stone walls and a sturdy wooden chest in the corner."
            ),
            .room(
                id: "eastRoom",
                name: "East Room",
                description: "A mysterious room with shimmering walls and a pedestal in the center."
            ),
            .room(
                id: "secretRoom",
                name: "Secret Room",
                description: "A hidden chamber with ancient treasures. The walls are covered in mysterious symbols."
            )
       )

       // Items
        world.add(
            .item(
                id: "lantern",
                name: "brass lantern",
                description: "An old brass lantern with a sturdy handle.",
                flags: .takeable, .device,
                synonyms: "lamp",
                location: "startRoom",
                LightSourceComponent(isOn: false)
            ),
            .item(
                id: "key",
                name: "small key",
                description: "A small brass key that gleams in the light.",
                flags: .takeable,
                synonyms: "brass key",
                location: "startRoom"
            ),
            .container(
                id: "chest",
                name: "wooden chest",
                description: "A sturdy wooden chest with a brass lock.",
                synonyms: "box", "trunk",
                location: "northRoom",
                isOpen: false,
                isTransparent: false,
                capacity: nil
            ),
            .item(
                id: "coin",
                name: "gold coin",
                description: "A shiny gold coin with strange markings.",
                flags: .takeable,
                synonyms: "treasure", "money",
                location: "chest"
            ),
            .item(
                id: "pedestal",
                name: "stone pedestal",
                description: "A stone pedestal with an indentation that looks like it would fit a coin.",
                synonyms: "stand", "plinth",
                location: "eastRoom",
                StateComponent(
                    ["hasCoin": false]
                )
            )
        )

        // Set the player's starting location explicitly after adding objects
        world.movePlayer(to: "startRoom")

        // Connect rooms
        world.connect(from: "startRoom", direction: .north, to: "northRoom")

        // Create a conditional exit to the east that requires the lantern to be on
        world.connectConditional(
            from: "startRoom",
            direction: .east,
            conditionalExit: ConditionalExit(
                to: "eastRoom",
                when: { world in
                    print("--- Checking East Exit Condition ---")
                    guard
                        let lantern = world.find("lantern"),
                        let lightSource = lantern.find(LightSourceComponent.self)
                    else {
                        print("--- East Exit: Failed to find lantern or component ---")
                        return false
                    }
                    print("--- East Exit: Lantern found, isOn = \(lightSource.isOn) ---")
                    let result = lightSource.isOn
                    print("--- East Exit: Condition result = \(result) ---")
                    return result
                },
                blockedMessage: "It's too dark to see any passage to the east."
            )
        )

        // Add a conditional exit from the east room to the secret room
        world.connectConditional(
            from: "eastRoom",
            direction: .north,
            conditionalExit: .requiresObject(
                to: "secretRoom",
                object: "key",
                blockedMessage: "You need a key to unlock this door."
            )
        )

        // Add return paths
        world.connect(
            from: "eastRoom",
            direction: .west,
            to: "startRoom",
            bidirectional: false
        )

        world.connect(
            from: "secretRoom",
            direction: .south,
            to: "eastRoom",
            bidirectional: false
        )

        // Schedule a repeating atmospheric event
        world.scheduleEvent("atmosphereEvent", delay: 3, isRepeating: true)

        return world
    }

    func defineCustomActions() -> [CustomAction] {
        [
            CustomAction(verb: "light") { context in
                guard
                    let directObject = context.directObject,
                    directObject == "lantern"
                else {
                    return [.showText("You don't see anything to light.")]
                }

                return [
                    .showText("You light the lantern, casting a warm glow around you."),
                    .playSound("lantern_lit")
                ]
            }
        ]
    }

    func defineEventHandlers() -> [EventHandler] {
        [
            EventHandler(id: "atmosphereEvent") { world in
                // Get the player's current location
                guard let location = world.playerLocation else {
                    return []
                }

                return switch location.id {
                case "startRoom":
                    [.showText("A gentle breeze blows through the small room.")]
                case "northRoom":
                    [.showText("Sunlight streams through the window, casting shadows on the floor.")]
                default:
                    []
                }
            },

            EventHandler(id: "examineLanternEvent") { world in
                [.showText("The lantern seems to glow a bit brighter momentarily.")]
            }
        ]
    }
}
