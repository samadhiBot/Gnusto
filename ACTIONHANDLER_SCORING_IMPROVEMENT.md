# Action Handler Scoring System Improvement

## Overview

This document describes the sophisticated action handler scoring system implemented to replace the naive "first-match wins" approach with a smart selection algorithm that chooses the most specific matching handler for each command.

## Problem Statement

The original `findActionHandler(for:)` method in `GameEngine.swift` had several critical flaws:

1. **First-match wins without validation**: It returned the first handler with a matching verb, even if that handler's syntax rules couldn't actually parse the command structure
2. **No specificity consideration**: A handler with `.match(.take, .directObject)` should beat `.match(.verb, .directObject)` for a "take" command, but the original system didn't consider this
3. **Missing syntax validation**: It didn't check if required objects, particles, or other syntax elements were present in the command
4. **Order dependency**: Handler registration order determined precedence instead of logical specificity

### Example Problem Scenario

```swift
// Handler 1: Generic but encountered first
.match(.verb, .directObject)  // Score: 115

// Handler 2: More specific but never reached
.match(.take, .directObject)  // Score: 215 (but never considered)
```

The original system would choose Handler 1 and never evaluate Handler 2, even though Handler 2 is objectively more specific for "take" commands.

## Solution: Sophisticated Scoring System

### Core Algorithm

The new system evaluates **ALL** handlers and scores them based on specificity:

1. **Find all potentially matching handlers** instead of just the first one
2. **Score each handler** based on how well it matches the command
3. **Return the highest-scoring handler**

### Scoring Rules

The scoring system uses the following hierarchy (higher scores = better matches):

#### Base Scores
- **0**: No match (handler cannot process this command)
- **100-199**: Basic verb match (`handler.verbs` contains `command.verb`)
- **200-299**: Specific verb match (`.specificVerb` matches exactly)

#### Bonus Points
- **+10**: Required direct object is present when needed
- **+10**: Required indirect object is present when needed  
- **+20**: Required particle matches exactly (high bonus for precision)
- **+10**: Required direction is present when needed
- **+5**: Handler has syntax rules (more structured than verb-only handlers)

#### Failure Conditions (Score = 0)
- Handler specifies verbs but none match the command
- Handler has syntax rules but none can parse the command structure
- Required objects are missing from the command
- Required particles don't match
- Handler has neither verbs nor syntax rules

### Implementation Details

The new `findActionHandler(for:)` method:

```swift
private func findActionHandler(for command: Command) -> ActionHandler? {
    var bestHandler: ActionHandler?
    var bestScore = 0

    for handler in actionHandlers {
        let score = scoreHandlerForCommand(handler: handler, command: command)
        if score > bestScore {
            bestScore = score
            bestHandler = handler
        }
    }

    return bestHandler
}
```

Key helper methods:

- `scoreHandlerForCommand(handler:command:)`: Main scoring logic
- `scoreSyntaxRuleForCommand(syntaxRule:command:)`: Detailed syntax rule evaluation
- `couldHandlerMatchCommand(_:_:)`: Updated to use the scoring system

## Demonstrated Improvements

### Test Case 1: Specific vs Generic Handlers
```
Command: "take lamp"

GenericTakeHandler (.match(.verb, .directObject)):     Score: 115
SpecificTakeHandler (.match(.take, .directObject)):    Score: 215 ✅

Result: SpecificTakeHandler chosen (more specific)
```

### Test Case 2: Particle Precision
```
Command: "turn on lamp"

TurnHandler (.match(.verb, .directObject)):            Score: 115
TurnOnHandler (.match(.verb, .on, .directObject)):     Score: 135 ✅

Result: TurnOnHandler chosen (particle match bonus)
```

### Test Case 3: Complex Syntax Requirements
```
Command: "put key in box"

SimpleHandler (.match(.verb, .directObject)):                           Score: 115
PutInHandler (.match(.verb, .directObject, .in, .indirectObject)):      Score: 145 ✅

Result: PutInHandler chosen (handles full command structure)
```

### Test Case 4: Missing Requirements
```
Command: "take" (no object)

TakeHandler (.match(.verb, .directObject)):            Score: 0 ❌

Result: No handler matches (required object missing)
```

### Test Case 5: Wrong Particle
```
Command: "turn off lamp"

TurnOnHandler (.match(.verb, .on, .directObject)):     Score: 0 (wrong particle)
TurnHandler (.match(.verb, .directObject)):            Score: 115 ✅

Result: TurnHandler chosen (TurnOnHandler fails particle requirement)
```

## Benefits

### 1. **Deterministic Selection**
Handler selection is now based on objective specificity scores rather than registration order.

### 2. **True Syntax Validation**
Handlers are only selected if they can actually parse the command structure.

### 3. **Maximum Specificity**
The most specific applicable handler is always chosen, leading to more precise behavior.

### 4. **Order Independence**
Handler registration order no longer affects selection - the best match always wins.

### 5. **Extensibility**
The scoring system can easily be extended with new criteria as needed.

### 6. **Backward Compatibility**
Existing handlers continue to work - the improvement is purely in selection logic.

## Implementation Files

### Modified Files
- `Gnusto/Sources/GnustoEngine/Engine/GameEngine.swift`: Core scoring implementation and enhanced `extractVerbDefinitions`
- `Gnusto/Sources/GnustoEngine/Parsing/SyntaxRule.swift`: Enhanced with better documentation

### New Files
- `Gnusto/Tests/GnustoEngineTests/Engine/ActionHandlerScoringTests.swift`: Comprehensive test suite
- `Gnusto/Tests/GnustoEngineTests/Engine/ActionHandlerScoringMinimalTests.swift`: Focused test cases

### Key Fixes
- **Enhanced `extractVerbDefinitions`**: Now extracts verbs from both `handler.verbs` and specific verbs in syntax rules
- **Proper Vocabulary Registration**: Handlers using only specific verbs in syntax rules are now correctly registered

## Technical Notes

### Verbs Property vs Specific Verbs in Syntax Rules

A critical insight for understanding action handler behavior:

**The `verbs` property is only used for `.verb` tokens in syntax rules.** Specific verbs mentioned in syntax rules (like `.climb`, `.get`, `.sit`) do not need to appear in the `verbs` array.

```swift
// Example: ClimbOnActionHandler
public let syntax: [SyntaxRule] = [
    .match(.climb, .on, .directObject),    // Uses .climb specifically
    .match(.get, .on, .directObject),      // Uses .get specifically  
    .match(.sit, .on, .directObject),      // Uses .sit specifically
    .match(.mount, .directObject),         // Uses .mount specifically
]

public let verbs: [Verb] = []  // Empty! No .verb tokens in syntax rules
```

This means:
- **Handlers with only specific verbs** in syntax rules should have empty `verbs` arrays
- **Handlers with `.verb` tokens** need those verbs listed in the `verbs` array
- **Mixed handlers** can have both specific verbs in some rules and `.verb` tokens in others

The `extractVerbDefinitions` method must handle both cases:
1. Extract verbs from `handler.verbs` (for `.verb` syntax tokens)
2. Extract specific verbs from syntax rule patterns (for `.climb`, `.get`, etc.)

This ensures all verbs get properly registered in the vocabulary's `verbToSyntax` mapping.

### Case Insensitive Particle Matching
Particle matching is case-insensitive to handle variations like "turn ON lamp" vs "turn on lamp".

### Multiple Syntax Rules
When a handler has multiple syntax rules, the highest-scoring rule determines the handler's score.

### Performance Considerations
The scoring system evaluates all handlers for each command, but this is acceptable given:
- Typical games have relatively few action handlers (10-50)
- Command processing is not performance-critical
- The benefits of correct selection far outweigh the minimal overhead

## Future Enhancements

Potential improvements to the scoring system:

1. **Weighted Scoring**: Different types of matches could have configurable weights
2. **Context Awareness**: Scores could consider game state or player context
3. **Learning System**: Handler selection could adapt based on player behavior patterns
4. **Ambiguity Resolution**: System could prompt for clarification when multiple handlers have identical scores

## Conclusion

The new action handler scoring system transforms command processing from a crude "first match" approach to a sophisticated selection algorithm that ensures the most appropriate handler is always chosen. This improvement makes interactive fiction games more responsive, predictable, and extensible while maintaining full backward compatibility with existing code.

The system demonstrates the power of applying proper software engineering principles (specificity-based scoring, comprehensive validation, deterministic selection) to game engine design.