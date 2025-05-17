# Dynamic Content and Action Handling [DONE]

Based on the analysis of the Inform 6 "Cloak of Darkness" source, the next major phase of development for the Gnusto engine will focus on enhancing dynamic content generation and action handling. This phase aims to replicate the flexibility and power of classic IF systems like Inform 6 while maintaining modern Swift practices and SOLID principles.

### Key Findings from "Cloak of Darkness"

1. **Dynamic Descriptions**

   - **Current State:** `Item.description` is a static `String`.
   - **Desired State:** Dynamic descriptions based on game state, similar to the Inform 6 hook example.
   - **Implementation Options:**
     - **Closure-based:** `(Item, GameEngine) -> String` for maximum flexibility.
     - **Handler Pattern:** Use a `descriptionHandlerID` to reference external logic.
     - **Data-Driven Logic:** Define `Codable` structures to describe dynamic behavior.

2. **Location-Specific Behavior**

   - **Current State:** Limited or no support for location-specific action handling.
   - **Desired State:** Locations should be able to intercept and react to actions performed within them.
   - **Example:** The `bar` in "Cloak of Darkness" checks for darkness and modifies the `message.number` based on player actions.

3. **Item-Specific Action Handlers**

   - **Current State:** Basic action handling, if any.
   - **Desired State:** Items should have `before` and `after` routines for action validation and side effects.
   - **Example:** The `cloak` prevents dropping outside the `cloakroom` and modifies the `bar`'s light state.

4. **Custom State on Objects**

   - **Current State:** Limited to boolean properties via `Item.attributes`.
   - **Desired State:** Support for custom, mutable state (e.g., counters, strings) on items and locations.
   - **Example:** The `message` object tracks disturbance via an integer `number` property.

5. **Game State Modification**

   - **Current State:** Basic game state management.
   - **Desired State:** Actions and descriptions should be able to modify game state, including score and game ending conditions.
   - **Example:** Reading the `message` sets `deadflag` to end the game.

6. **Parser Flexibility**
   - **Current State:** Basic command parsing with synonyms and adjectives.
   - **Desired State:** Support for custom grammar and advanced noun phrase parsing.
   - **Example:** The `parse_name` routine for the `cloak` and custom verb definitions.

### Implementation Strategy

1. **Dynamic Descriptions**

   - Evaluate the trade-offs between closure-based and handler-based approaches.
   - Ensure `Codable` conformance for game state serialization.
   - Implement a registry or data-driven system for dynamic logic.

2. **Action Handling System**

   - Design a robust, event-driven action handling system.
   - Allow items, locations, and global rules to hook into the action processing pipeline.
   - Support `before` and `after` routines for validation and side effects.

3. **Custom State Management**

   - Extend the `Item` and `Location` models to support custom, mutable state.
   - Ensure state changes are properly serialized and deserialized.

4. **Parser Enhancements**
   - Improve the command parser to handle custom grammar and advanced parsing logic.
   - Support synonyms, adjectives, and potentially custom parsing routines.

### Conclusion

This phase represents a significant step forward in making the Gnusto engine as powerful and flexible as classic IF systems. By focusing on dynamic content and action handling, we can provide game developers with the tools they need to create rich, interactive experiences.

**Next Steps:**

- [x] Begin with a detailed design document for the action handling system.
- [x] Implement a proof of concept for dynamic descriptions using the handler pattern.
- [x] Gradually introduce support for custom state and enhanced parsing.
- [x] Test and iterate based on feedback from the development community.
- [ ] Conditional exits
