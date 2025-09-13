# Action Handler Development Guide

Action handlers are the core components that process player commands in the Gnusto Interactive Fiction Engine. This guide covers the design principles, implementation patterns, and best practices for creating effective action handlers.

## Overview

Action handlers translate player intent into game responses and state changes. They follow a careful scoring system that selects the most appropriate handler for each command, ensuring players receive contextually relevant feedback.

### Core Responsibilities

- **Parse player commands** using syntax rules and verb matching
- **Validate prerequisites** (reachability, game state, etc.)
- **Generate meaningful responses** that keep players engaged
- **Apply minimal state changes** through the StateChange pipeline
- **Update pronouns and context** for natural language flow

## Design Philosophy

### Keep It Simple

Action handlers should provide plausible responses without over-engineering game-specific logic:

```swift
// ✅ Good: Generic, reusable
if !targetItem.hasFlag(.isTakeable) {
    throw ActionResponse.itemNotTakable(targetItem.name)
}

// ❌ Avoid: Game-specific logic in engine
if targetItem.hasFlag(.isSponge) && !player.hasFlag(.hasWetHands) {
    throw await ActionResponse.feedback("The sponge is too dry to pick up.")
}

// ❌ Bad: Name or description based matching
if targetItem.name.contains("sand") {
    throw await ActionResponse.feedback("The sand slips through your fingers.")
}
```

**Principle**: The engine provides building blocks; game developers add specificity by overriding default behavior.

### State Changes Flow Through Pipeline

All game state modifications must use the `StateChange` system. Action handlers return an `ActionResult`, which includes a player-facing message and any changes to the game state.

```swift
// ✅ Correct: Using StateChange pipeline
public func process(context: ActionContext) async throws -> ActionResult {
    // Process inbound command, validate correctness...

    return ActionResult(
        engine.messenger.taken(),
        await engine.setFlag(.isTouched, on: targetItem),
        await engine.updatePronouns(to: targetItem)
    )
}
```

### Use MessageProvider for ActionHandler Responses

Never hardcode `ActionHandler` response text. Use the `MessageProvider` for consistency and localization:

```swift
// ✅ Good: Using MessageProvider
throw await ActionResponse.feedback(
    engine.messenger.itemNotTakable(item.withDefiniteArticle)
)

// ❌ Bad: Hardcoded text
throw await ActionResponse.feedback("You can't take that!")
```

The `MessageProvider` contains default responses for a wide variety of commands. Game developers can subclass `MessageProvider` to replace the default responses as needed to fit their own game's language and tone.

## Action Handler Structure

### Basic Implementation

```swift
public struct ExampleActionHandler: ActionHandler {
    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.pick, .up, .directObject)
    ]

    public let synonyms: [Verb] = [.take, .get, .grab]

    public let requiresLight: Bool = true

    public func process(context: ActionContext) async throws -> ActionResult {
        // Implementation details...
    }
}
```

### Syntax Rules and the Synonyms Property

The `synonyms` property contains verb synonyms that match any `.verb` tokens in syntax rules.

```swift
public let syntax: [SyntaxRule] = [
    .match(.verb, .directObject),      // `.verb` is generic
    .match(.pick, .up, .directObject)  // `.pick` is specific
]

public let synonyms: [Verb] = [.take, .get, .grab]  // Match the generic `.verb` token
```

| ✅ Matching Commands | ❌ Non-matching Commands |
| --- | --- |
| `TAKE SWORD` | `TAKE UP SWORD` |
| `GET SWORD` | `PICK SWORD` |
| `GRAB SWORD` | |
| `PICK UP SWORD` | |

### Action Processing Patterns

Real action handlers follow much simpler patterns than you might expect. Here are the most common patterns from actual handlers:

#### Pattern 1: Simple Object Action (like BlowActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = command.directObjectItemID else {
        // Handle no-object case
        return ActionResult(engine.messenger.blow())
    }

    guard await engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    let targetItem = try await engine.item(targetItemID)

    return ActionResult(
        engine.messenger.blowOn(item: targetItem.withDefiniteArticle),
        await engine.setItemFlag(targetItemID, .isTouched, to: true),
        await engine.updatePronouns(to: targetItem)
    )
}
```

#### Pattern 2: Character Interaction (like AskActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let characterID = command.directObjectItemID else {
        throw await ActionResponse.feedback(engine.messenger.askWhom())
    }

    let character = try await engine.item(characterID)

    guard character.isCharacter else {
        throw await ActionResponse.feedback(
            engine.messenger.cannotAskAboutThat(item: character.withDefiniteArticle)
        )
    }

    guard await engine.playerCanReach(characterID) else {
        throw ActionResponse.itemNotAccessible(characterID)
    }

    // Handle different scenarios based on command structure
    if let topic = command.indirectObject {
        return try await processDirectAsk(character: character, topic: topic, engine: engine)
    } else {
        return await promptForTopic(character: character, engine: engine)
    }
}
```

#### Pattern 3: Conditional Response (like AttackActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = command.directObjectItemID else {
        throw await ActionResponse.feedback(engine.messenger.doWhat(command.verb))
    }

    let targetItem = try await engine.item(targetItemID)

    guard await engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    // Different responses based on target and weapon
    let message: String
    if !targetItem.isCharacter {
        message = engine.messenger.attackNonCharacter(item: targetItem.withDefiniteArticle)
    } else if command.indirectObject == nil {
        message = engine.messenger.attackWithBareHands(character: targetItem.withDefiniteArticle)
    } else {
        // Handle weapon attacks...
        message = engine.messenger.attackWithWeapon(/* ... */)
    }

    return ActionResult(
        message,
        await engine.setItemFlag(targetItemID, .isTouched, to: true),
        await engine.updatePronouns(to: targetItem)
    )
}
```

#### Pattern 4: Optional Objects (like BreatheActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = command.directObjectItemID else {
        // No object - general action
        return ActionResult(engine.messenger.breatheResponse())
    }

    // Object specified - targeted action
    let targetItem = try await engine.item(targetItemID)

    guard await engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    return ActionResult(
        engine.messenger.breatheOnResponse(item: targetItem.withDefiniteArticle),
        await engine.setItemFlag(targetItemID, .isTouched, to: true),
        await engine.updatePronouns(to: targetItem)
    )
}
```

**Key Insights from Real Handlers:**

- Most handlers are much simpler than you might expect
- Common pattern: validate → get item → check accessibility → generate response
- State changes are minimal: usually just `.isTouched` and pronoun updates
- Complex logic is often just conditional responses, not complex state manipulation
- ActionResult constructor accepts variadic StateChange arguments for convenience

## Universal Object Handling

Universal objects represent concepts like "sky", "ground", "walls" that are implicitly present but don't need explicit `Item` objects. Players should receive a reasonable response when they try to interact with these: "LOOK AT THE SKY", "DIG THE GROUND", "TOUCH THE WALLS".

### Supporting Universal Objects

Action handlers can support universal objects during normal processing:

```swift
public struct ExamineActionHandler: ActionHandler {
    // ... other properties ...

    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle both items and universals
        for directObjectRef in command.directObjects {
            switch directObjectRef {
            case .item(let itemID):
                // Handle regular items

            case .universal(let universal):
                // Handle universals like .sky, .ground, .walls
                return ActionResult(
                    engine.messenger.nothingSpecialAbout(universal.displayName)
                )

            default:
                // Handle other types...
            }
        }
    }
}
```

### Universal Object Patterns

```swift
// Digging handler that works with ground/earth universals
UniversalObject.diggableUniversals.contains(universal)

// Movement handler that only works with architectural features
UniversalObject.architecturalUniversals.contains(universal)
```

### Universal Object Categories

Universal objects are pre-categorized for convenience:

- `UniversalObject.diggableUniversals`: ground, earth, soil, dirt, mud, sand
- `UniversalObject.waterUniversals`: water, river, stream, lake, pond, ocean, sea
- `UniversalObject.architecturalUniversals`: floor, walls, wall, ceiling, roof
- `UniversalObject.outdoorUniversals`: sky, sun, moon, stars, clouds, etc.
- `UniversalObject.indoorUniversals`: ceiling, walls, floor, etc.

This system ensures players get reasonable responses to common interactions without requiring game developers to create explicit items for every possible universal concept.

## Handler Selection and Scoring

The engine uses a sophisticated scoring system to select the most appropriate handler:

### Scoring Hierarchy

- **0**: No match (handler cannot process command)
- **100-199**: Basic verb match
- **200-299**: Specific verb match
- **+10**: Required objects present
- **+20**: Required particles match
- **+5**: Handler has syntax rules

### Example Scoring

```
Command: `TURN ON LAMP`

TurnHandler   .match(.verb, .directObject):       Score: 115
TurnOnHandler .match(.turn, .on, .directObject):  Score: 235 ✅

Result: TurnOnHandler chosen (more specific)
```

This scoring system ensures the most appropriate handler is always selected.

## Testing Requirements

Action handlers require comprehensive test coverage (80-90%) using Swift Testing.

### Essential Test Categories

#### 1. Syntax Rule Testing

Test every supported pattern and verify unsupported patterns fail:

```swift
@Test("TAKE syntax works")
func testTakeSyntax() async throws {
    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    try await engine.execute("take lamp")

    let output = await mockIO.flush()
    expectNoDifference(output, """
        > take lamp
        Taken.
        """)
}

@Test("Invalid syntax patterns are rejected")
func testInvalidSyntax() async throws {
    // Test patterns not in syntax rules
}
```

#### 2. Validation Testing

Test all prerequisite checks:

```swift
@Test("Requires item to be takeable")
func testRequiresTakeable() async throws {
    // Setup: Non-takeable item
    // When: Try to take it
    // Then: Should fail with appropriate message
}
```

#### 3. State Change Testing

Verify successful actions produce expected state changes:

```swift
@Test("Take moves item to player")
func testTakeMovesItem() async throws {
    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    try await engine.execute("take lamp")

    let finalState = try await engine.item("lamp")
    #expect(try await finalState.playerIsHolding)
}
```

### Critical Testing Principles

**Always test through the full engine pipeline!**

```swift
// ✅ RIGHT: Test complete flow
try await engine.execute("take lamp")

// ❌ WRONG: Skip parser (misses real bugs)
let command = Command(verb: .take, directObject: "lamp", rawInput: "take lamp")
try await handler.perform(command: command, engine: engine)
```

### Standard Test Setup

```swift
@Test("Test description")
func testSomething() async throws {
    // Given: Complete game setup
    let testRoom = Location(
        id: "testRoom",
        .name("Test Room"),
        .inherentlyLit
    )

    let testItem = Item(
        id: "testItem",
        .name("test item"),
        .isTakable,
        .in(.startRoom)
    )

    let game = MinimalGame(
        player: Player(in: .startRoom),
        locations: testRoom,
        items: testItem
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    // When: Execute through full pipeline
    try await engine.execute("take test item")

    // Then: Verify results
    let output = await mockIO.flush()
    expectNoDifference(output, """
        > take test item
        Taken.
        """)

    let finalState = try await engine.item("testItem")
    #expect(try await finalState.playerIsHolding)
}
```

## Common Patterns

### Handling ALL Commands

```swift
if command.isAllCommand {
    // Skip problematic items, don't throw errors
    guard await engine.playerCanReach(itemID) else {
        continue
    }

    // Provide summary message if nothing processed
    if processedItems.isEmpty {
        return ActionResult(
            message: engine.messenger.nothingHereToTake(),
            changes: []
        )
    }
}
```

### Preposition Delegation

```swift
// Delegate to specialized handlers for prepositional variants
if context.hasPreposition(.in, .on) {
    let lookInsideHandler = LookInsideActionHandler()
    return try await lookInsideHandler.process(context: context)
}
```

### Multiple Object Processing

```swift
var processedItems: [Item] = []

for directObjectRef in command.directObjects {
    // Process each object...
    processedItems.append(item)
}

// Update pronouns appropriately
let pronounChanges = await engine.updatePronouns(to: processedItems)
allStateChanges.append(contentsOf: pronounChanges)
```

## Best Practices

### Do's

- ✅ Use specific verbs in syntax rules when possible
- ✅ Test through the complete engine pipeline
- ✅ Keep validation logic generic and reusable
- ✅ Use MessageProvider for all responses
- ✅ Handle ALL commands gracefully
- ✅ Update pronouns after processing
- ✅ Flow state changes through StateChange pipeline

### Don'ts

- ❌ Don't hardcode response text
- ❌ Don't bypass the parser in tests
- ❌ Don't put game-specific logic in engine handlers
- ❌ Don't forget to handle edge cases (empty input, unreachable items)
- ❌ Don't use `.contains()` for message testing
- ❌ Don't modify game state directly

### Message Testing Best Practices

```swift
// ✅ RIGHT: Exact message matching with command echo
let output = await mockIO.flush()
expectNoDifference(output, """
    > take lamp
    Taken.
    """)

// ❌ WRONG: Partial matching
#expect(output.contains("Taken"))

// ❌ WRONG: Missing command echo
expectNoDifference(output, "Taken.")
```

## Advanced Topics

### Custom Question Handling

For handlers that need to ask follow-up questions:

```swift
// Two-phase asking pattern
if command.indirectObject == nil {
    let prompt = "What do you want to ask \(character.withDefiniteArticle) about?"

    let questionChanges = await ConversationManager.askForTopic(
        prompt: prompt,
        characterID: characterID,
        originalCommand: command,
        engine: engine
    )

    return ActionResult(message: prompt, changes: questionChanges)
}
```

### Handler Specialization

Create specialized handlers for complex scenarios:

```swift
// Generic handler for most cases
public struct TakeActionHandler: ActionHandler { ... }

// Specialized handler for specific game mechanics
public struct TakeFromContainerActionHandler: ActionHandler {
    public let syntax: [SyntaxRule] = [
        .match(.take, .directObject, .from, .indirectObject)
    ]
    // Specialized logic for container interactions
}
```

### Item Event Handlers

For item-specific behavior, use ItemEventHandlers instead of complex action handler logic:

```swift
// In game code, not engine
public struct MagicLampEventHandler: ItemEventHandler {
    public func handleExamine(context: ActionContext) async -> ActionResult? {
        // Custom examine behavior for magic lamp
        return ActionResult(message: "The lamp glows with inner light...")
    }
}
```

## Integration with Engine

### Handler Registration

Handlers are automatically discovered and registered:

```swift
// Engine automatically finds and registers handlers
public static let defaultActionHandlers: [ActionHandler] = [
    TakeActionHandler(),
    ExamineActionHandler(),
    // ... other handlers
]
```

### Vocabulary Integration

The engine automatically extracts verbs from handlers for vocabulary registration:

```swift
// Both explicit verbs and syntax-embedded verbs are registered
public let synonyms: [Verb] = [.grab]              // Explicit
public let syntax: [SyntaxRule] = [
    .match(.take, .directObject)                // .take auto-registered
]
```

## Contributing to the Engine

When contributing action handlers to the engine:

1. **Keep them generic** - avoid game-specific logic
2. **Comprehensive testing** - 80-90% coverage required
3. **Follow established patterns** - consistent with existing handlers
4. **Document thoroughly** - clear inline documentation
5. **Consider backward compatibility** - don't break existing games

### Pull Request Requirements

- All tests pass with high coverage
- Follows established code style
- Includes comprehensive test suite
- Documents any breaking changes
- Provides clear examples of usage

## Summary

Action handlers are the bridge between player intent and game response. By following these principles--keeping logic generic, using the StateChange pipeline, testing comprehensively, and providing engaging responses--you'll create handlers that enhance the interactive fiction experience while maintaining clean, maintainable code.

The Gnusto engine's sophisticated handler selection system ensures that the most appropriate handler is always chosen, allowing developers to create both broad, generic handlers and specialized, context-specific ones that work together seamlessly.
