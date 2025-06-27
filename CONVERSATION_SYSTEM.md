# Gnusto Interactive Fiction Engine - Conversation System

The Gnusto Interactive Fiction Engine now includes a comprehensive conversation system that enables ZIL-style interactive fiction dialog patterns. This system supports two-phase asking, yes/no confirmation dialogs, and graceful recovery when players don't directly answer questions.

## Features

### 🎭 Two-Phase Asking
Players can initiate conversations without specifying a topic, and the engine will prompt for clarification:

```
> ASK TROLL
What do you want to ask the ugly troll about?

> TREASURE
The ugly troll doesn't seem to know anything about the golden treasure.
```

### ❓ Yes/No Confirmation Dialogs
Ambiguous commands trigger confirmation dialogs to clarify player intent:

```
> NIBBLE APPLE
Do you mean you want to eat the red apple?

> YES
You eat the red apple. It was delicious!
```

### 🔄 Graceful Recovery
The system handles non-responses gracefully, clearing question state when players execute different commands:

```
> ASK TROLL
What do you want to ask the ugly troll about?

> INVENTORY
You are carrying:
    a chocolate cookie

> # Question automatically cleared, game continues normally
```

## Architecture

### Core Components

#### 1. ConversationManager
The central coordinator for all conversation interactions:

- **Question State Management**: Tracks pending questions using GlobalIDs
- **Response Processing**: Interprets player input as question responses
- **State Cleanup**: Automatically clears orphaned question states
- **Type Safety**: Strongly typed question contexts and responses

```swift
// Check if a question is pending
let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)

// Process input as a potential question response
let response = await ConversationManager.processQuestionResponse(
    input: "treasure",
    engine: engine
)
```

#### 2. Enhanced AskActionHandler
Supports both traditional and two-phase asking patterns:

- **Direct Asking**: `"ASK WIZARD ABOUT SPELL"` (immediate response)
- **Two-Phase Asking**: `"ASK WIZARD"` → prompt → `"SPELL"` (guided interaction)
- **Backward Compatibility**: Existing ask commands continue to work

#### 3. YesNoQuestionHandler
Utility for creating confirmation dialogs:

- **Multiple Synonyms**: Recognizes "yes", "y", "sure", "ok", "no", "n", "nope", etc.
- **Action Integration**: Seamlessly executes confirmed actions
- **Disambiguation Support**: Helps clarify ambiguous player commands

#### 4. Modified GameEngine.processTurn()
Enhanced turn processing with conversation awareness:

```swift
// 1. Check for pending questions first
if await ConversationManager.hasPendingQuestion(engine: self) {
    if let response = await ConversationManager.processQuestionResponse(input, engine: self) {
        // Handle question response
        return
    }
    // Fall through to normal processing (clears question)
}

// 2. Normal command processing continues...
```

### State Management

All conversation state flows through the established StateChange pipeline:

```swift
// Question state stored as GlobalIDs
public static let pendingQuestionType = GlobalID("pendingQuestionType")
public static let pendingQuestionPrompt = GlobalID("pendingQuestionPrompt") 
public static let pendingQuestionSource = GlobalID("pendingQuestionSource")
public static let pendingQuestionContext = GlobalID("pendingQuestionContext")
```

**Benefits:**
- ✅ Persistent across game saves/loads
- ✅ Integrated with existing state validation
- ✅ Automatic cleanup and garbage collection
- ✅ Full audit trail in change history

## Usage Examples

### Creating Two-Phase Asking

```swift
public struct CustomAskActionHandler: ActionHandler {
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let characterID = command.directObjectItemID else {
            throw ActionResponse.prerequisiteNotMet("Ask whom?")
        }
        
        if let topic = command.indirectObject {
            // Direct asking - process immediately
            return try await processDirectAsk(character: characterID, topic: topic, engine: engine)
        } else {
            // Two-phase asking - prompt for topic
            let character = try await engine.item(characterID)
            let prompt = "What do you want to ask \(character.withDefiniteArticle) about?"
            
            let questionChanges = await ConversationManager.askForTopic(
                prompt: prompt,
                characterID: characterID,
                originalCommand: command,
                engine: engine
            )
            
            return ActionResult(message: prompt, changes: questionChanges)
        }
    }
}
```

### Creating Yes/No Confirmation

```swift
public struct ExampleActionHandler: ActionHandler {
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // ... validation logic ...
        
        // Create confirmation dialog
        return await YesNoQuestionHandler.askToDisambiguate(
            question: "Do you mean you want to eat \(item.withDefiniteArticle)?",
            clarifiedCommand: Command(verb: .eat, directObject: command.directObject, rawInput: "eat \(item.name)"),
            originalCommand: command,
            engine: engine
        )
    }
}
```

### Custom Question Processing

```swift
// Check current question state
if let context = await ConversationManager.getCurrentQuestion(engine: engine) {
    switch context.type {
    case .topic:
        // Handle topic selection
    case .yesNo:
        // Handle yes/no response
    case .choice:
        // Handle multiple choice selection
    }
}
```

## Testing

The conversation system includes comprehensive test coverage using Swift Testing:

### Test Categories

1. **State Management Tests**
   - Question creation and storage
   - State cleanup and recovery
   - Global ID persistence

2. **Response Processing Tests**
   - Topic interpretation and parsing
   - Yes/no synonym recognition
   - Invalid input handling

3. **Integration Tests**
   - Full conversation flows
   - Handler coordination
   - Engine pipeline integration

4. **Edge Case Tests**
   - Nested questions
   - Interruption handling
   - Error recovery

### Example Test

```swift
@Test("Two-phase asking completes successfully")
func testTwoPhaseAskingCompleteFlow() async throws {
    let (engine, mockIO) = await createTestEngine()
    
    // Phase 1: Ask without topic
    try await engine.execute("ask wizard")
    let phase1Output = await mockIO.flush()
    expectNoDifference(phase1Output, """
        > ask wizard
        What do you want to ask the old wizard about?
        """)
    
    // Verify question is pending
    let hasPending = await ConversationManager.hasPendingQuestion(engine: engine)
    #expect(hasPending == true)
    
    // Phase 2: Provide topic
    try await engine.execute("treasure")
    let phase2Output = await mockIO.flush()
    expectNoDifference(phase2Output, """
        > treasure
        The old wizard doesn't seem to know anything about the golden treasure.
        """)
    
    // Verify question is cleared
    let stillPending = await ConversationManager.hasPendingQuestion(engine: engine)
    #expect(stillPending == false)
}
```

## Implementation Notes

### Design Principles

1. **SOLID Architecture**: Clean separation of concerns with dependency injection
2. **State Change Pipeline**: All modifications flow through validated StateChange objects  
3. **Backward Compatibility**: Existing commands and handlers continue to work unchanged
4. **Type Safety**: Strongly typed throughout with proper error handling
5. **Test-Driven**: Comprehensive test coverage with realistic scenarios

### ZIL Compatibility

The conversation system faithfully recreates classic ZIL (Zork Implementation Language) interaction patterns:

- **Two-phase asking**: Matches ZIL's `ASK ACTOR` → `ASK-DEFAULT` → topic selection pattern
- **Disambiguation**: Mirrors ZIL's disambiguation routines for ambiguous player input
- **Graceful degradation**: Handles unexpected input like original ZIL interpreters
- **Character interaction**: Supports ZIL-style character conversation mechanics

### Performance Considerations

- **Lazy Evaluation**: Question processing only occurs when questions are pending
- **Minimal Overhead**: No performance impact on normal (non-conversation) commands
- **Efficient Storage**: Question state uses minimal global variables
- **Quick Cleanup**: Automatic state cleanup prevents memory leaks

## Integration with Existing Code

The conversation system integrates seamlessly with existing Gnusto components:

### Action Handlers
- **No Breaking Changes**: Existing handlers work without modification
- **Opt-in Enhancement**: Handlers can add conversation support incrementally
- **Pipeline Integration**: Conversations flow through the established action handler pipeline

### Game State
- **StateChange Compliance**: All conversation state flows through StateChange objects
- **Save/Load Support**: Conversation state persists across game sessions
- **Validation**: Integrated with existing state validation mechanisms

### Message Provider
- **Consistent Messaging**: Uses established MessageProvider patterns
- **Customizable**: Game developers can override conversation messages
- **Localization Ready**: Messages support the existing localization framework

## Future Enhancements

### Planned Features

1. **Choice Questions**: Multiple choice dialog trees
2. **Conversation Memory**: Characters remember previous conversations
3. **Advanced Disambiguation**: Context-aware disambiguation with learning
4. **Conversation Scripting**: DSL for complex conversation flows
5. **Voice Acting Integration**: Support for audio responses and synthesis

### Extension Points

The system is designed for easy extension:

```swift
// Custom question types
enum CustomQuestionType: String, Codable {
    case multipleChoice
    case textInput
    case numericInput
}

// Custom response processors
extension ConversationManager {
    static func processCustomResponse(_ input: String, context: QuestionContext) async -> ActionResult? {
        // Custom response handling logic
    }
}
```

## Summary

The Gnusto Interactive Fiction Engine's conversation system provides a robust, ZIL-compatible foundation for creating rich interactive fiction experiences. By combining modern Swift architecture with classic IF interaction patterns, it enables developers to create engaging, nostalgic interactive fiction while maintaining clean, maintainable code.

**Key Benefits:**
- 🎯 **Faithful ZIL Recreation**: Authentic classic IF conversation patterns
- 🏗️ **Modern Architecture**: Clean, type-safe Swift implementation  
- 🔄 **Graceful Recovery**: Robust handling of unexpected player input
- 🧪 **Comprehensive Testing**: Full test coverage with realistic scenarios
- 🔌 **Easy Integration**: Seamless compatibility with existing game code
- 📈 **Future-Proof**: Extensible design for advanced conversation features

The conversation system represents a significant enhancement to the Gnusto engine, bringing it closer to the full capabilities of classic interactive fiction development systems while maintaining the benefits of modern software engineering practices.