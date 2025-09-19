# Dynamic Properties and Events

Learn how to work with dynamic game objects that evolve and respond to player actions.

## Overview

In Gnusto, you define static game objects--Items and Locations--within your game target, but once the game is running, you'll be working with dynamic _proxy_ objects: ``ItemProxy``, ``LocationProxy`` and ``PlayerProxy``.

These proxies are the key to a living, breathing game world. While your static definitions provide the initial blueprint, proxies give you access to objects that evolve with every turn. They respond to player actions, environmental changes, time-based events, and complex game logic--all while maintaining Swift 6 concurrency safety.

## Game Structure and Organization

### The Game Blueprint

Your ``GameBlueprint`` implementation contains essential game metadata, like the title and introductory text.

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

### Static Object Definitions

You define your game's ``Item`` and ``Location`` objects in logical groupings that represent parts of the world. Looking at the included example games, you'll see several organizational approaches.

The _Zork_ contents are principally organized by map region. However the Thief and Troll objects are complex enough to deserve their own files.

```
Zork1/
├── main.swift
├── World
│   ├── BeneathHouse.swift
│   ├── CoalMine.swift
│   ├── CyclopsHideaway.swift
│   ├── Dam.swift
│   ├── Forest.swift
│   ├── ...
│   ├── Temple.swift
│   ├── Thief.swift
│   ├── Troll.swift
│   └── Underground.swift
├── Zork1.swift
└── ZorkMessenger.swift
```

_Cloak of Darkness_, on the other hand, is small enough for everything to fit in a single file that represents the contents of the Opera House.

```
CloakOfDarkness/
├── CloakOfDarkness.swift
├── main.swift
└── OperaHouse.swift
```

Opening [OperaHouse.swift](https://github.com/samadhiBot/Gnusto/blob/main/Executables/CloakOfDarkness/OperaHouse.swift) reveals the game's static locations and items:

```swift
struct OperaHouse {
    // ...
    let cloakroom = Location(
        id: .cloakroom,
        .name("Cloakroom"),
        .description(
            """
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """
        ),
        .exits(.east(.foyer)),
        .inherentlyLit
    )

    let hook = Item(
        id: .hook,
        .adjectives("small", "brass"),
        .in(.cloakroom),
        .omitDescription,
        .isSurface,
        .name("small brass hook"),
        .synonyms("peg"),
    )
    // ...
}
```

These locations and items represent the state of the game world as the adventure begins. However once a player sets out in your game world, your focus as the game's architect moves beyond the static places and things.

The state of the world evolves with every player command. The Gnusto engine translates the player's natural language commands into a stream of events that touch the various locations, items and characters in your game.

You as the game's architect can anticipate events, and write handlers that respond to them. When a player enters a location, or performs some action there, you can respond. When they interact with an item, you'll receive an event on that item, and can respond however you choose.

This is how you construct layers of dynamic behavior around the locations, items and characters in your game, and this is where the magic happens--where your game world comes alive.

## Dynamic Proxies

When you work with items and locations, you almost never work with the simple ``Item`` or ``Location`` objects directly.

Instead, you'll work with ``ItemProxy``, ``LocationProxy``, and ``PlayerProxy`` objects. These proxies take into account:

- The underlying object's current properties
- Event handlers that can intervene and modify behavior
- Property computers that calculate values dynamically
- The broader context of the living game world

This architecture enables sophisticated interactions while keeping your game definitions clean and declarative.

### Item Event Handlers

``ItemEventHandler`` objects are your primary tool for making items behave dynamically. They intercept player commands and can modify, replace, or enhance the default behavior. Here's how the cloak in _Cloak of Darkness_ responds to being dropped:

```swift
let cloakHandler = ItemEventHandler(for: .cloak) {
    before(.drop, .insert) { context, _ in
        guard await context.player.location.id == .cloakroom else {
            throw ActionResponse.feedback(
                "This isn't the best place to leave a smart cloak lying around."
            )
        }
        return nil  // Pass control back to default action handling
    }

    after { context, command in
        guard await context.player.location.id == .cloakroom else {
            return nil
        }

        if command.hasIntent(.drop, .insert) {
            var changes = [
                await context.location(.bar).setFlag(.isLit)
            ]
            if await context.player.score < 1 {
                changes.append(await context.player.updateScore(by: 1))
            }
            return ActionResult(changes: changes)
        }

        if command.hasIntent(.take) {
            return ActionResult(
                await context.location(.bar).clearFlag(.isLit)
            )
        }

        return nil
    }
}
```

Notice how the handler works with proxy objects through the `context` parameter. The `context.player` is a `PlayerProxy`, and `context.player.location` and `context.location(.bar)` are `LocationProxy` objects. These proxies have access to the current, dynamic state of the game world.

### Location Event Handlers

``LocationEventHandler`` objects work similarly for locations, allowing you to create rooms that respond to their environment and the player's actions:

```swift
let barHandler = LocationEventHandler(for: .bar) {
    // First: if location is lit, yield to normal processing
    beforeTurn { context, _ in
        if await context.location.isLit {
            return ActionResult.yield
        }
        return nil  // not handled, try next matcher
    }

    // Second: handle north movement in dark
    beforeTurn(.move) { context, command in
        if command.direction == .north {
            return ActionResult.yield
        } else {
            return ActionResult(
                "Blundering around in the dark isn't a good idea!",
                await context.engine.adjustGlobal(.barMessageDisturbances, by: 2)
            )
        }
    }

    // Third: handle meta commands in dark
    beforeTurn(.meta) { _, _ in
        return ActionResult.yield
    }

    // Fourth: catch-all for other commands in dark
    beforeTurn { context, _ in
        return ActionResult(
            "In the dark? You could easily disturb something!",
            await context.engine.adjustGlobal(.barMessageDisturbances, by: 1)
        )
    }
}
```

The `context.location` here is a `LocationProxy` for the Bar location that knows whether the room is currently light or dark--not just from a static flag, but considering potential light sources, the cloak's magical darkness effect, and any other dynamic factors.

### Computed Properties

While event handlers respond to player commands, ``ItemComputer`` and ``LocationComputer`` property computers calculate dynamic property values on demand based on the current game state. This allows properties like an object `.description` to change as the world evolves:

```swift
let kitchenComputer = LocationComputer(for: .kitchen) {
    locationProperty(.description) { context in
        let kitchenWindow = await context.item(.kitchenWindow)
        let windowState = await kitchenWindow.isOpen ? "open" : "slightly ajar"
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

Property computers work seamlessly with the proxy system. When you check the `kitchen.description`, the proxy finds the computed property and uses it. For another object without a computed property, it falls back to the static description.

## Working with Proxies in Daemons

The ``Daemon`` demonstrates another aspect of the living world. It's a recurring event that happens independently of player actions. It works exclusively with proxy objects to implement time-based behaviors:

```swift
static let swordDaemon = Daemon { engine in
    let currentLocation = await engine.player.location
    var newGlowLevel = 0

    // Check for monsters in current location (highest priority)
    let currentLocationItems = await currentLocation.items
    var monstersInCurrentLocation: [ItemProxy] = []
    for item in currentLocationItems {
        if await item.isCharacter {
            monstersInCurrentLocation.append(item)
        }
    }

    if monstersInCurrentLocation.isNotEmpty {
        newGlowLevel = 2  // Very bright glow
    } else {
        // Check adjacent locations for monsters
        for exit in await currentLocation.exits {
            guard let destination = exit.destinationID else {
                continue
            }
            let adjacentLocation = await engine.location(destination)
            let adjacentLocationItems = await adjacentLocation.items
            var monstersInAdjacentLocation: [ItemProxy] = []
            for item in adjacentLocationItems {
                if await item.isCharacter {
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

This daemon creates a sword that responds to the presence of monsters--a perfect example of how proxies enable dynamic, context-aware behavior. The daemon uses `engine.player.location` to get the player's current `LocationProxy`, checks for monsters using `ItemProxy` properties, and explores adjacent locations through more proxy objects.

## Understanding Dynamic vs Static Properties

The distinction between static and dynamic properties is fundamental to understanding Gnusto's architecture.

### Static Properties

These describe the initial state of your game world--how things are when the adventure begins:

- Basic flags like `.isTakable`, `.isLightSource`, `.isDevice`
- Initial names and descriptions
- Starting locations
- Base item properties

Static properties are what you define when creating your `Item` and `Location` objects. They're the blueprint.

### Dynamic Properties

These describe the real-time state of your game world as it evolves:

- **Location lighting**: `isLit` considers all light sources present
- **Item visibility**: `isVisible` accounts for darkness and container states
- **Computed descriptions**: Can change based on item or environmental state
- **Container states**: `isEmpty`, `currentLoad` reflect actual contents
- **Location accessibility**: Exit availability may change with game state

Dynamic properties are what you access through proxy objects during gameplay. They represent the living world.

## Key ItemProxy Accessors

When working with `ItemProxy` objects in your event handlers and daemons, these are the most useful dynamic accessors:

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

Essential `LocationProxy` accessors for implementing dynamic location behavior:

- **`isLit`**: Whether the location is currently illuminated
- **`description`**: Current location description (may change based on state)
- **`exits`**: Available exits (may change based on conditions)
- **`name`**: Display name of the location
- **`withDefiniteArticle`**: Location name with appropriate article
- **`items`**: All items currently in the location

## Why Proxies Matter

The proxy system is what transforms your static game definitions into a living, breathing world. Here's why this architecture is so powerful:

**Automatic State Synchronization**: Proxies automatically compute the current state based on all relevant factors. When you check if a location `isLit`, the proxy considers the room's inherent lighting, all light sources present, items the player is carrying, and any magical effects--all without you having to write that logic explicitly.

**Clean Separation of Concerns**: Your static definitions remain simple and declarative. Dynamic behaviors are added through event handlers and property computers, keeping different aspects of your game logic organized and maintainable.

**Concurrency Safety**: The proxy system handles all the complexity of concurrent state access, ensuring your game remains thread-safe even as it grows more complex.

**Extensibility**: New behaviors can be added without modifying existing code. Want a room that changes description based on time of day? Add a property computer. Need an item that behaves differently when wet? Add an event handler.

## Next Steps

This article focused on reading and accessing dynamic properties through proxies. For information about modifying game state through proxies, see:

- **State Changes and the Action Pipeline**: How to safely modify game state through the action pipeline
- **Time-Based Events**: Using daemons and fuses with dynamic properties
- **Custom Computed Properties**: Adding your own dynamic property calculations

The proxy system is the foundation of Gnusto's dynamic, evolving game world--master it to create sophisticated interactive fiction experiences.

