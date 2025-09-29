# Action Handler Development Guide

Action handlers are the core components that process player commands in the Gnusto Interactive Fiction Engine. With 80+ built-in handlers covering everything from basic interactions to combat, conversations, and complex puzzle mechanics, this guide covers the design principles, implementation patterns, and best practices for creating effective action handlers that work with the modern proxy-based architecture.

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

    return await ActionResult(
        message,
        item.setFlag(.isTouched),
        item.clearFlag(.isInflated)
    )
}
```

### Use MessageProvider for ActionHandler Responses

Never hardcode `ActionHandler` response text. Always use the `Messenger` system (via `context.msg` or `engine.messenger`) for consistency and localization:

```swift
// ✅ Good: Using Messenger system
throw await ActionResponse.feedback(
    context.msg.itemNotTakable(item.withDefiniteArticle)
)

// ❌ Bad: Hardcoded text
throw await ActionResponse.feedback("You can't take that!")
```

The `Messenger` system contains default responses for a wide variety of commands. Game developers can subclass `MessageProvider` to replace the default responses as needed to fit their own game's language and tone, and the engine automatically uses their custom messenger throughout all interactions.

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

Real action handlers follow much simpler patterns than you might expect, but now work through the proxy system for safe state access. Here are the most common patterns from actual handlers:

#### Pattern 1: Simple Object Action (like BlowActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = context.command.directObjectItemID else {
        // Handle no-object case
        return ActionResult(context.msg.blow())
    }

    guard await context.engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    let targetItem = await context.item(targetItemID)

    return await ActionResult(
        context.msg.blowOn(item: targetItem.withDefiniteArticle),
        targetItem.setFlag(.isTouched)
    )
}
```

#### Pattern 2: Character Interaction (like AskActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let characterID = context.command.directObjectItemID else {
        throw await ActionResponse.feedback(context.msg.askWhom())
    }

    let character = await context.item(characterID)

    guard await character.isCharacter else {
        throw await ActionResponse.feedback(
            context.msg.cannotAskAboutThat(item: character.withDefiniteArticle)
        )
    }

    guard await context.engine.playerCanReach(characterID) else {
        throw ActionResponse.itemNotAccessible(characterID)
    }

    // Handle different scenarios based on command structure
    if let topic = context.command.indirectObject {
        return try await processDirectAsk(character: character, topic: topic, context: context)
    } else {
        return await promptForTopic(character: character, context: context)
    }
}
```

#### Pattern 3: Combat Action (like AttackActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = context.command.directObjectItemID else {
        throw await ActionResponse.feedback(context.msg.doWhat(context.command.verb))
    }

    let targetItem = await context.item(targetItemID)

    guard await context.engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    // Different responses based on target and weapon
    let message: String
    if !await targetItem.isCharacter {
        message = context.msg.attackNonCharacter(item: targetItem.withDefiniteArticle)
    } else if context.command.indirectObject == nil {
        message = context.msg.attackWithBareHands(character: targetItem.withDefiniteArticle)
    } else {
        // Handle weapon attacks - may trigger combat system
        return try await handleCombatAttack(target: targetItem, context: context)
    }

    return ActionResult(
        message,
        targetItem.setFlag(.isTouched),
        await context.engine.updatePronouns(to: targetItem)
    )
}
```

#### Pattern 4: Optional Objects (like BreatheActionHandler)

```swift
public func process(context: ActionContext) async throws -> ActionResult {
    guard let targetItemID = context.command.directObjectItemID else {
        // No object - general action
        return ActionResult(context.msg.breatheResponse())
    }

    // Object specified - targeted action
    let targetItem = await context.item(targetItemID)

    guard await context.engine.playerCanReach(targetItemID) else {
        throw ActionResponse.itemNotAccessible(targetItemID)
    }

    return ActionResult(
        context.msg.breatheOnResponse(item: targetItem.withDefiniteArticle),
        targetItem.setFlag(.isTouched),
        await context.engine.updatePronouns(to: targetItem)
    )
}
```

**Key Insights from Real Handlers:**

- Most handlers are much simpler than you might expect
- Common pattern: validate → get item proxy → check accessibility → generate response
- State changes are minimal: usually just `.isTouched` and pronoun updates
- Complex logic is often just conditional responses, not complex state manipulation
- The proxy system provides safe, concurrent access to both static and computed properties
- Combat and conversation handlers may delegate to specialized subsystems
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
        for directObjectRef in context.command.directObjects {
            switch directObjectRef {
            case .item(let itemID):
                // Handle regular items through proxy system
                let item = await context.item(itemID)

            case .universal(let universal):
                // Handle universals like .sky, .ground, .walls
                return ActionResult(
                    context.msg.nothingSpecialAbout(universal.displayName)
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
Universal.diggableUniversals.contains(universal)

// Movement handler that only works with architectural features
Universal.architecturalUniversals.contains(universal)
```

### Universal Object Categories

Universal objects are pre-categorized for convenience:

- `Universal.diggableUniversals`: ground, earth, soil, dirt, mud, sand
- `Universal.waterUniversals`: water, river, stream, lake, pond, ocean, sea
- `Universal.architecturalUniversals`: floor, walls, wall, ceiling, roof
- `Universal.outdoorUniversals`: sky, sun, moon, stars, clouds, etc.
- `Universal.indoorUniversals`: ceiling, walls, floor, etc.

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
    let testRoom = Location(
        id: .startRoom,
        .name("Test Room"),
        .inherentlyLit
    )

    let testItem = Item(
        id: "lamp",
        .name("brass lamp"),
        .isTakable,
        .in(.startRoom)
    )

    let game = MinimalGame(
        player: Player(in: .startRoom),
        locations: testRoom,
        items: testItem
    )

    let (engine, mockIO) = await GameEngine.test(blueprint: game)

    try await engine.execute("take lamp")

    await mockIO.expectOutput("""
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

    let finalState = await engine.item("lamp")
    #expect(await finalState.playerIsHolding)
}
```

### Critical Testing Principles

**Always test through the full engine pipeline!**

```swift
// ✅ RIGHT: Test complete flow through parser and action system
try await engine.execute("take lamp")

// ❌ WRONG: Skip parser (misses real bugs)
let command = Command(verb: .take, directObject: "lamp", rawInput: "take lamp")
try await handler.process(context: ActionContext(command: command, engine: engine))
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
    await mockIO.expectOutput("""
        > take test item
        Taken.
        """)

    let finalState = await engine.item("testItem")
    #expect(await finalState.parent == .player)
}
```

## Common Patterns

### Handling ALL Commands

```swift
if context.command.isAllCommand {
    // Skip problematic items, don't throw errors
    guard await context.engine.playerCanReach(itemID) else {
        continue
    }

    // Provide summary message if nothing processed
    if processedItems.isEmpty {
        return ActionResult(
            context.msg.nothingHereToTake()
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
var processedItems: [ItemProxy] = []

for directObjectRef in context.command.directObjects {
    // Process each object through proxy system...
    processedItems.append(item)
}
```

## Best Practices

### Do's

- ✅ Use specific verbs in syntax rules when possible
- ✅ Test through the complete engine pipeline
- ✅ Keep validation logic generic and reusable
- ✅ Use Messenger system (context.msg) for all responses
- ✅ Handle ALL commands gracefully
- ✅ Update pronouns after processing
- ✅ Flow state changes through StateChange pipeline via proxy system

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
await mockIO.expectOutput("""
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
// Two-phase asking pattern integrated with conversation system
if context.command.indirectObject == nil {
    let prompt = "What do you want to ask \(character.withDefiniteArticle) about?"

    let questionChanges = await ConversationManager.askForTopic(
        prompt: prompt,
        characterID: characterID,
        originalCommand: context.command,
        context: context
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

For item-specific behavior, use ItemEventHandlers with the proxy system:

```swift
// In game code, not engine
let lampHandler = ItemEventHandler(for: .magicLamp) {
    before(.examine) { context, command in
        // Custom examine behavior for magic lamp with proxy access
        let lamp = await context.item(.magicLamp)
        let glowLevel = await lamp.property("glowLevel", type: Int.self) ?? 0

        let message = glowLevel > 0 ?
            "The lamp glows with inner light..." :
            "The lamp appears ordinary."

        return ActionResult(message)
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
