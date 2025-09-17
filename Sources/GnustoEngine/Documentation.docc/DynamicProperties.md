# Dynamic Properties and the Proxy System

Learn how to work with dynamic game objects that evolve and respond to player actions through the powerful proxy system.

## Overview

In Gnusto, you define static game objects (items and locations) in separate files within your game target, but once the game is running, you work primarily with **proxy objects** (`ItemProxy`, `LocationProxy`, `PlayerProxy`) that provide access to dynamic, evolving game state.

These proxies give you access to objects that can change with every turn in response to actions, environmental factors, time-based events, and game logic. This enables sophisticated interactive fiction mechanics while maintaining Swift 6 concurrency safety.

## Game Structure and Organization

### GameBlueprint: Game Metadata

Your `GameBlueprint` implementation contains essential game metadata--not the actual game objects:

```swift
public struct CloakOfDarkness: GameBlueprint {
    public let title = "Cloak of Darkness"
    public let abbreviatedTitle = "Cloak"
    public let introduction = """
        A basic IF demonstration.

        Hurrying through the rainswept November night, you're glad to see the
        bright lights of the Opera House...
        """
    public let release = "0.0.3"
    public let maximumScore = 2
    public let player = Player(in: .foyer)

    // Note: All game content registration (items, locations, handlers, etc.)
    // is automatically handled by GnustoAutoWiringPlugin
}
```

### Static Game Objects: Defined Separately

You define your actual game content (items, locations, event handlers) in other files within your game target, organized however you like. Here's a real example from _Cloak of Darkness_:

```swift
struct OperaHouse {
    // MARK: - Locations

    let foyer = Location(
        id: .foyer,
        .name("Foyer of the Opera House"),
        .description(
            """
            You are standing in a spacious hall, splendidly decorated in red
            and gold, with glittering chandeliers overhead. The entrance from
            the street is to the north, and there are doorways south and west.
            """
        ),
        .exits(
            .south(.bar),
            .west(.cloakroom),
            .north(
                blocked: """
                    You've only just arrived, and besides, the weather outside
                    seems to be getting worse.
                    """
            )
        ),
        .inherentlyLit
    )

    let bar = Location(
        id: .bar,
        .name("Bar"),
        .description(
            """
            The bar, much rougher than you'd have guessed after the opulence
            of the foyer to the north, is completely empty. There seems to
            be some sort of message scrawled in the sawdust on the floor.
            """
        ),
        .exits(.north(.foyer))
    )

    // MARK: - Items

    let cloak = Item(
        id: .cloak,
        .name("velvet cloak"),
        .description(
            """
            A handsome cloak, of velvet trimmed with satin, and slightly
            spattered with raindrops. Its blackness is so deep that it
            almost seems to suck light from the room.
            """
        ),
        .adjectives("handsome", "dark", "black", "velvet", "satin"),
        .in(.player),
        .isTakable,
        .isWearable,
        .isWorn
    )

    let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.cloakroom),
        .omitDescription,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg")
    )
}
```

## From Static Definitions to Dynamic Proxies

### Dynamic Item Proxies

Once the game is running, you access these objects through proxies that reflect their current, dynamic state. Here's how event handlers work with real proxies:

```swift
let cloakHandler = ItemEventHandler(for: .cloak) {
    before(.drop, .insert) { context, _ in
        guard try await context.player.location.id == .cloakroom else {
            throw ActionResponse.feedback(
                "This isn't the best place to leave a smart cloak lying around."
            )
        }
        return nil
    }

    after { context, command in
        guard try await context.player.location.id == .cloakroom else {
            return nil
        }

        if command.hasIntent(.drop, .insert) {
            var changes = [
                try await context.engine.location(.bar).setFlag(.isLit)
            ]
            if await context.player.score < 1 {
                changes.append(await context.player.updateScore(by: 1))
            }
            return ActionResult(changes: changes)
        }

        if command.hasIntent(.take) {
            return ActionResult(
                try await context.engine.location(.bar).clearFlag(.isLit)
            )
        }

        return nil
    }
}
```

### Dynamic Location Proxies

Location handlers work with `LocationProxy` objects that provide dynamic location state:

```swift
let barHandler = LocationEventHandler(for: .bar) {
    // First: if location is lit, yield to normal processing
    beforeTurn { context, _ in
        if try await context.location.isLit {
            return ActionResult.yield
        }
        return nil  // not handled, try next matcher
    }

    // Handle commands in the dark
    beforeTurn { context, _ in
        return ActionResult(
            "In the dark? You could easily disturb something!",
            await context.engine.adjustGlobal(.barMessageDisturbances, by: 1)
        )
    }
}
```

### Dynamic Computed Properties

You can define properties that are calculated dynamically based on game state using computers:

```swift
static let kitchenComputer = LocationComputer(for: .kitchen) {
    locationProperty(.description) { context in
        let kitchenWindow = context.gameState.items[.kitchenWindow]
        let isWindowOpen = kitchenWindow?.properties[.isOpen]?.toBool ?? false
        let windowState = isWindowOpen ? "open" : "slightly ajar"
        return .string(
            """
            You are in the kitchen of the white house. A table seems to
            have been used recently for the preparation of food. A passage
            leads to the west and a dark staircase can be seen leading
            upward. A dark chimney leads down and to the east is a small
            window which is \(windowState).
            """
        )
    }
}
```

## Working with Proxies in Daemons

Daemons use proxies to implement recurring game world events. Here's a real example from Zork 1 where a sword glows when monsters are nearby:

```swift
static let swordDaemon = Daemon { engine in
    let currentLocation = try await engine.player.location
    var newGlowLevel = 0

    // Check for monsters in current location (highest priority)
    let currentLocationItems = try await currentLocation.items
    var monstersInCurrentLocation: [ItemProxy] = []
    for item in currentLocationItems {
        if try await item.isCharacter {
            monstersInCurrentLocation.append(item)
        }
    }

    if monstersInCurrentLocation.isNotEmpty {
        newGlowLevel = 2  // Very bright glow
    } else {
        // Check adjacent locations for monsters
        for exit in try await currentLocation.exits {
            guard let destination = exit.destinationID else {
                continue
            }
            let adjacentLocation = try await engine.location(destination)
            let adjacentLocationItems = try await adjacentLocation.items
            var monstersInAdjacentLocation: [ItemProxy] = []
            for item in adjacentLocationItems {
                if try await item.isCharacter {
                    monstersInAdjacentLocation.append(item)
                }
            }

            if monstersInAdjacentLocation.isNotEmpty {
                newGlowLevel = 1  // Faint blue glow
                break
            }
        }
    }

    // Always update the glow level and show message if glowing
    let currentGlowLevel = await engine.global(.swordGlowLevel) ?? 0

    // Determine the glow message based on current level
    let message =
        switch newGlowLevel {
        case 1:
            "Your sword is glowing with a faint blue glow."
        case 2:
            "Your sword is glowing very brightly."
        default:
            ""  // Level 0 - no message when not glowing
        }

    // Update the glow level if it changed
    if newGlowLevel != (currentGlowLevel.toInt ?? 0) {
        let glowChange = StateChange.setGlobalInt(id: .swordGlowLevel, value: newGlowLevel)

        return if message.isEmpty {
            ActionResult(glowChange)
        } else {
            ActionResult(message, glowChange)
        }
    } else if message.isNotEmpty {
        // Level didn't change but sword is still glowing - show the message
        return ActionResult(message)
    }

    return nil
}
```

## Understanding Dynamic vs Static Properties

### Static Properties

These describe the state of your game's locations, items, NPCs, etc. at the start of the game. Examples include:

- Basic flags like `.isTakable`, `.isLightSource`, `.isDevice`
- Initial names and descriptions
- Starting locations
- Base item properties

### Dynamic Properties

These describe the state of your game's locations, items, NPCs, etc. in realtime, based on an evolving game state and dynamic event handlers and property computers. Examples include:

- **Location lighting**: `isLit` considers all light sources present
- **Item visibility**: `isVisible` accounts for darkness and container states
- **Computed descriptions**: Can change based on item or environmental state
- **Container states**: `isEmpty`, `currentLoad` reflect actual contents
- **Location accessibility**: Exit availability may change with game state

## Key ItemProxy Accessors

Here are some of the most useful `ItemProxy` accessors for dynamic game logic:

- **`isProvidingLight`**: Whether the item is currently providing light
- **`isVisible`**: Can the player see this item (affects command recognition)
- **`isTakable`**: Can the player pick this up (may change dynamically)
- **`isOpen`**: Current open/closed state for containers and doors
- **`isEmpty`**: Whether a container has no items inside
- **`capacity`**: How much a container can hold
- **`currentLoad`**: How much a container is currently holding
- **`description`**: Current description (may change based on state)
- **`location`**: Where the item currently is (recursive location resolution)

## Key LocationProxy Accessors

Essential `LocationProxy` accessors for dynamic location behavior:

- **`isLit`**: Whether the location is currently illuminated
- **`description`**: Current location description (may change based on state)
- **`exits`**: Available exits (may change based on conditions)
- **`name`**: Display name of the location
- **`withDefiniteArticle`**: Location name with appropriate article
- **`items`**: All items currently in the location

## Why Proxies Matter

ItemProxy, LocationProxy and PlayerProxy provide automatic state synchronization. As places and objects evolve over time through player actions, proxies automatically handle state computations as needed. For example, `isLit` considers:

- Location's inherent lighting (`.inherentlyLit` flag)
- All light sources in the location
- Player's carried light sources
- Environmental modifiers

## Next Steps

This article focused on reading and accessing dynamic properties through proxies. For information about modifying game state through proxies, see:

- **State Changes and the action Pipeline**: How to safely modify game state through the action pipeline
- **Time-Based Events**: Using daemons and fuses with dynamic properties
- **Custom Computed Properties**: Adding your own dynamic property calculations

The proxy system is the foundation of Gnusto's dynamic, evolving game world - master it to create sophisticated interactive fiction experiences.
