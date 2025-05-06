// MARK: - Default Handlers

extension GameEngine {
    /// Default action handlers provided by the engine.
    /// Games can override these via the `DefinitionRegistry`.
    static let defaultActionHandlers: [VerbID: EnhancedActionHandler] = [
        // Movement & World Interaction
        "close": CloseActionHandler(),
        "examine": ExamineActionHandler(),
        "go": GoActionHandler(),
        "insert": InsertActionHandler(),
        "lock": LockActionHandler(),
        "look": LookActionHandler(),
        "open": OpenActionHandler(),
        "put-on": PutOnActionHandler(),
        "unlock": UnlockActionHandler(),

        // Inventory Management
        "drop": DropActionHandler(),
        "inventory": InventoryActionHandler(),
        "remove": RemoveActionHandler(),
        "take": TakeActionHandler(),
        "wear": WearActionHandler(),

        // Other Actions
        "listen": ListenActionHandler(),
        "read": ReadActionHandler(),
        "smell": SmellActionHandler(),
        "taste": TasteActionHandler(),
        "think": ThinkAboutActionHandler(),
        "touch": TouchActionHandler(),
        "turn off": TurnOffActionHandler(),
        "turn on": TurnOnActionHandler(),
        "wait": WaitActionHandler(),

        // Meta Actions
        "quit": QuitActionHandler(),
        "score": ScoreActionHandler(),

        // TODO: Add more default handlers (Attack, Read, Eat, Drink, etc.)
    ]
}
