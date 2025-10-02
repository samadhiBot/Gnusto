# Game Structure and Dynamic Behavior

Learn how to organize your game world and bring it to life with dynamic proxies and event handlers.

## Organizing Your Game

![Gnusto Proxies](gnusto-proxies.png)

Gnusto separates your game into two layers: **static definitions** that describe your game world's initial state, and **dynamic proxies** that represent the living, evolving world during gameplay. This architecture lets you write clean, declarative game content while enabling sophisticated runtime behaviors through event handlers and computed properties.

### The Game Blueprint

Your ``GameBlueprint`` serves as the entry point, containing essential metadata and the initial game configuration. Most of the game blueprint can be generated automatically by the <doc:GnustoAutoWiringPlugin>.

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

### Structuring Your World

Organize your ``Item`` and ``Location`` definitions in logical groupings that represent your game world. The framework is flexible, so choose the structure that makes sense for your game's scope and complexity.

**Large games** like _Zork_ benefit from regional organization, with special files for complex entities:

```
Zork1/
├── main.swift
├── World
│   ├── BeneathHouse.swift     # Underground areas
│   ├── Dam.swift              # Dam complex
│   ├── Forest.swift           # Forest region
│   ├── ...
│   ├── Thief.swift            # Complex NPC with behaviors
│   └── Troll.swift            # Another complex NPC
├── Zork1.swift                # Game blueprint
└── ZorkMessenger.swift        # Custom Zork-specific responses
```

**Smaller games** like _Cloak of Darkness_ can fit everything in a single world file:

```
CloakOfDarkness/
├── CloakOfDarkness.swift      # Game blueprint
├── OperaHouse.swift           # All locations and items
└── main.swift
```

### Defining Static Content

Your static definitions describe the initial state of the world -- how things are when the adventure begins. For example, inside the Opera House in _Cloak of Darkness_, there is a cloakroom, and in that cloakroom there is a small brass hook screwed to the wall:

```swift
struct OperaHouse {
    // ...
    let cloakroom = Location(.cloakroom)
        .name("Cloakroom")
        .description(
            """
            The walls of this small room were clearly once lined with hooks,
            though now only one remains. The exit is a door to the east.
            """
        )
        .east(.foyer)
        .inherentlyLit

    let hook = Item(.hook)
        .adjectives("small", "brass")
        .in(.cloakroom)
        .omitDescription
        .isSurface
        .name("small brass hook")
        .synonyms("peg")
    // ...
}
```

These definitions are just the starting point. Once the game begins, everything becomes dynamic.

## The Living World: Dynamic Proxies

During gameplay, you never work with static ``Item`` or ``Location`` objects directly. Instead, the engine provides **proxy objects** -- ``ItemProxy``, ``LocationProxy``, and ``PlayerProxy`` -- that represent the current, evolving state of your world.

### Why Proxies?

Proxies bridge the gap between your static definitions and the dynamic game world. They:

- **Track current state**: Is the door open? Is the room lit? Where is the sword now?
- **Apply context**: A room's lighting depends on _any_ light sources present, not just a static flag
- **Enable intervention**: Event handlers can modify behaviors on the fly
- **Compute properties**: Descriptions can change based on game state
- **Ensure safety**: Handle concurrent access in Swift 6's strict concurrency model

### Static vs. Dynamic Properties

Learning this distinction is key to understanding Gnusto:

#### Static properties

- Defined at compile time
- Initial flags: `.isTakable`, `.isLightSource`, `.isContainer`
- Starting descriptions, names, adjectives and synonyms
- Base item properties and initial locations

#### Dynamic properties

- Computed at runtime through proxies
- `isLit`: Considers all light sources, darkness effects, and conditions
- `isVisible`: Accounts for darkness, container states, and concealment
- `description`: Can change based on world state via property computers
- `currentLoad`/`isEmpty`: Reflect actual container contents
- `isProvidingLight`: Whether an item is actually illuminating (e.g. lit lamp vs. unlit lamp)

## Making Things Happen: Event Handlers

Event handlers intercept player commands and add dynamic behaviors to your items and locations. They work exclusively with proxy objects to access and modify the current game state.

### Item Event Handlers

Make items respond intelligently to player actions:

```swift
let cloakHandler = ItemEventHandler(for: .cloak) {
    before(.drop, .insert) { context, _ in
        guard await context.player.location == .cloakroom else {
            throw ActionResponse.feedback(
                "This isn't the best place to leave a smart cloak lying around."
            )
        }
        return nil  // Pass control back to default action handling
    }

    after { context, command in
        guard await context.player.location == .cloakroom else {
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
            return await ActionResult(
                context.location(.bar).clearFlag(.isLit)
            )
        }

        return nil
    }
}
```

Notice how the handler uses proxies throughout: `context.player` is a ``PlayerProxy``, `context.player.location` is a ``LocationProxy``, and these proxies know the current state of the world.

### Location Event Handlers

Create rooms that respond to their environment:

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

## Computed Properties

While event handlers respond to commands, property computers calculate dynamic values on demand:

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

The proxy system seamlessly integrates computed properties -- when you access `kitchen.description`, the proxy checks for a computed property first, and falls back to the static definition if none exists.

## Time-Based Behaviors: Daemons

Daemons run independently of player actions, using proxies to implement autonomous behaviors:

```swift
let swordDaemon = Daemon { engine, state in
    let currentLocation = await engine.player.location
    var newGlowLevel: SwordBrightness = .notGlowing

    // Check for monsters in current location (highest priority)
    for item in await currentLocation.items where await item.isCharacter {
        newGlowLevel = .glowingBrightly
        break
    }

    if newGlowLevel != .glowingBrightly {
        // Check adjacent locations for monsters
        for exit in await currentLocation.exits {
            guard let destination = exit.destinationID else { continue }
            let adjacentLocation = await engine.location(destination)
            for item in await adjacentLocation.items where await item.isCharacter {
                newGlowLevel = .glowingFaintly
                break
            }
        }
    }

    // Always update the glow level and show message if glowing
    let currentGlowLevel = state.getPayload(as: SwordBrightness.self) ?? .notGlowing

    // Do nothing if the glow level has not changed
    if newGlowLevel == currentGlowLevel { return nil }

    // Update and announce the glow level if it has changed
    return try ActionResult(
        newGlowLevel.description,
        .updateDaemonState(
            daemonID: .swordDaemon,
            daemonState: state.updatingPayload(newGlowLevel)
        )
    )
}
```

## Putting It All Together

The power of Gnusto's architecture becomes clear when these pieces work together:

1. **You define** clean, declarative items and locations
2. **The auto-wiring plugin generates** strongly-typed IDs and connective boilerplate
3. **Proxies provide** access to the living, dynamic world
4. **Event handlers** add sophisticated behaviors
5. **Property computers** make descriptions and states contextual
6. **Daemons and Fuses** create autonomous, time-based effects

This separation keeps your code organized, maintainable, and powerful -- letting you focus on crafting compelling interactive fiction rather than wrestling with infrastructure.

## Next Steps

- **State Changes and the Action Pipeline**: Safely modifying game state
- **Advanced Event Handling**: Complex command interception patterns
- **Custom Properties**: Extending the proxy system with your own computations
- **Combat Systems**: Building interactive combat with proxies and handlers
