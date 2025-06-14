# MessageProvider System Migration Status

## Overview

This document tracks the migration of hardcoded user-facing messages throughout the GnustoEngine to use the centralized MessageProvider system for localization and customization.

## Completed Work

### 1. Core MessageProvider Infrastructure ✅

- **MessageKey.swift**: Expanded with comprehensive enum cases for all user-facing messages
- **StandardMessageProvider.swift**: Implemented messages for all MessageKey cases
- **MessageProvider+Random.swift**: Added utility for random message selection from multiline strings
- **ActionContext**: Extended with `message(_:)` convenience method

### 2. Random Message System ✅

Implemented support for atmospheric commands with multiple response options:
- Messages stored as multiline strings (one option per line)
- `GameEngine.randomMessage(for:)` method selects random line
- `MessageProvider.selectRandomLine(from:using:)` utility method

### 3. Converted ActionHandlers ✅

**Atmospheric Commands:**
- ✅ BreatheActionHandler - Uses `.breatheResponses` with 5 random options
- ✅ CryActionHandler - Uses `.cryResponses` with 10 random options  
- ✅ DanceActionHandler - Uses `.danceResponses` with 11 random options (includes classic "Dancing is forbidden")
- ✅ CurseActionHandler - Uses `.curseResponses` (8 options) and `.curseTargetResponses(item:)` (5 options)

**Complex Action Commands:**
- ✅ ChompActionHandler - Uses `.chompResponses` for general chomping, specific messages for different item types
- ✅ AttackActionHandler - Uses `.attackNonCharacter(item:)`, `.attackWithBareHands(character:)`, etc.
- ✅ AskActionHandler - Uses `.askWhom`, `.askAboutWhat`, validation messages
- ✅ BurnActionHandler - Uses `.burnWhat`, `.burnToCatchFire(item:)`, `.burnJokingResponse`, etc.

**Basic Action Commands:**
- ✅ BlowActionHandler - Uses `.blowOnLightSource(item:)`, `.blowOnFlammable(item:)`, etc.
- ✅ ClimbActionHandler - Uses `.climbWhat`, `.climbSuccess(item:)`, `.climbFailure(item:)`
- ✅ ClimbOnActionHandler - Uses `.climbOnWhat`, `.climbOnFailure(item:)`
- ✅ CutActionHandler - Uses `.cutWhat`, `.cutWithTool(item:tool:)`, etc.

**Utility Commands:**
- ✅ DebugActionHandler - Uses `.debugRequiresObject`
- ✅ DeflateActionHandler - Uses `.deflateWhat`, `.cannotDeflate(item:)`
- ✅ DigActionHandler - Uses generic validation messages
- ✅ DrinkActionHandler - Uses `.drinkWhat`, `.canOnlyDrinkLiquids`, `.nothingToDrinkIn(container:)`
- ✅ EatActionHandler - Uses `.eatWhat`, `.canOnlyEatFood`, `.nothingToEatIn(container:)`
- ✅ EmptyActionHandler - Uses `.emptyWhat`, `.canOnlyEmptyContainers`
- ✅ InflateActionHandler - Uses `.inflateWhat`, `.cannotInflate(item:)`
- ✅ KickActionHandler - Uses `.kickWhat` and generic validation messages
- ✅ KissActionHandler - Uses `.kissWhat` and generic validation messages

### 4. MessageKey Categories ✅

**Question Prompts:** For missing direct/indirect objects
- `.askWhom`, `.attackWhat`, `.breatheWhat`, `.burnWhat`, etc.

**Validation Messages:** For invalid actions
- `.cannotActOnThat(verb:)`, `.cannotActWithThat(verb:)`, `.canOnlyActOnItems(verb:)`
- `.cannotDeflate(item:)`, `.cannotInflate(item:)`, `.cannotDrink(item:)`, etc.

**Atmospheric Responses:** Multi-line random selections
- `.breatheResponses`, `.cryResponses`, `.danceResponses`, `.chompResponses`, `.curseResponses`
- `.chompTargetResponses(item:)`, `.curseTargetResponses(item:)`

**Action-Specific:** Context-aware responses
- `.attackNonCharacter(item:)`, `.attackWithBareHands(character:)`, `.attackWithWeapon`
- `.blowOnLightSource(item:)`, `.burnToCatchFire(item:)`, `.cutWithTool(item:tool:)`

**Engine Errors:** Internal error handling
- `.actionHandlerMissingObjects(handler:)`, `.actionHandlerInternalError(handler:details:)`

## Remaining Work

### 1. ActionHandlers Still Using Hardcoded Messages ⚠️

Need to scan for and convert remaining handlers:
- EnterActionHandler
- ExamineActionHandler  
- FillActionHandler
- FindActionHandler
- JumpActionHandler
- KnockActionHandler
- LockActionHandler
- LookActionHandler
- LookInsideActionHandler
- LookUnderActionHandler
- Plus any others with hardcoded strings

### 2. ActionResponse Translation ⚠️

The `GameEngine.report(_ response: ActionResponse)` method already uses MessageProvider, but may need updates for new ActionResponse cases.

### 3. Parser Messages ⚠️

Parser error messages may still use hardcoded strings - need to audit:
- Unknown verb messages
- Grammar error messages  
- Ambiguity resolution messages

### 4. Game State Messages ⚠️

System messages that may need MessageProvider integration:
- Inventory listing
- Location descriptions
- Movement transition messages
- Score/status messages

## Testing Status

### 1. Tests Created ✅

- **MessageProviderRandomTests.swift**: Comprehensive tests for random message selection
- **MessageProviderActionTests.swift**: Tests for converted ActionHandlers

### 2. Test Coverage Areas ✅

- Random line selection from multiline messages
- GameEngine.randomMessage(for:) integration
- ActionContext.message(_:) convenience method
- Converted ActionHandler behavior
- Deterministic random selection with seeded RNG

## Usage Examples

### Basic Message Retrieval
```swift
let message = context.message(.taken)
// Returns: "Taken."
```

### Random Atmospheric Responses
```swift
let message = await engine.randomMessage(for: .breatheResponses)
// Returns one of 5 breathing responses randomly
```

### Parameterized Messages
```swift
let message = context.message(.attackNonCharacter(item: "box"))
// Returns: "I've known strange people, but fighting a box?"
```

### Custom Message Providers
```swift
class HorrorMessageProvider: StandardMessageProvider {
    override func message(for key: MessageKey) -> String {
        switch key {
        case .roomIsDark:
            return "The suffocating darkness presses in around you."
        default:
            return super.message(for: key)
        }
    }
}
```

## Migration Benefits

1. **Localization Ready**: All user-facing text centralized for translation
2. **Game Customization**: Developers can override specific messages for theme/tone
3. **Consistency**: Standardized message patterns across all ActionHandlers
4. **Maintainability**: Single source of truth for all text
5. **Random Variety**: Atmospheric commands provide engaging variety
6. **Testing**: Better testability with predictable message sources

## Next Steps

1. Complete remaining ActionHandler conversions
2. Audit and convert any remaining hardcoded strings
3. Expand test coverage for edge cases
4. Consider additional MessageKey categories as needed
5. Document custom MessageProvider creation for game developers
6. Add localization examples (Spanish, French, etc.)

## File Structure

```
Gnusto/Sources/GnustoEngine/Localization/
├── MessageKey.swift                 # All message identifiers
├── MessageProvider.swift            # Protocol definition  
├── StandardMessageProvider.swift    # English implementation
└── MessageProvider+Random.swift     # Random selection utilities

Gnusto/Tests/GnustoEngineTests/Localization/
├── MessageProviderRandomTests.swift
└── MessageProviderActionTests.swift
```
