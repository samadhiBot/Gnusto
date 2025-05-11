// MARK: - Default Handlers

extension GameEngine {
    /// Default action handlers provided by the engine.
    /// Games can override these via the `DefinitionRegistry`.
    static let defaultActionHandlers: [VerbID: ActionHandler] = [
        // Movement & World Interaction

        .close: CloseActionHandler(),
        .drop: DropActionHandler(),
        .examine: ExamineActionHandler(),
        .go: GoActionHandler(),
        .insert: InsertActionHandler(),
        .inventory: InventoryActionHandler(),
        .listen: ListenActionHandler(),
        .lock: LockActionHandler(),
        .look: LookActionHandler(),
        .open: OpenActionHandler(),
        .putOn: PutOnActionHandler(),
        .read: ReadActionHandler(),
        .remove: RemoveActionHandler(),
        .smell: SmellActionHandler(),
        .take: TakeActionHandler(),
        .taste: TasteActionHandler(),
        .thinkAbout: ThinkAboutActionHandler(),
        .touch: TouchActionHandler(),
        .turnOff: TurnOffActionHandler(),
        .turnOn: TurnOnActionHandler(),
        .unlock: UnlockActionHandler(),
        .wear: WearActionHandler(),

        // Meta Actions

//        .brief: BriefActionHandler(),
//        .help: HelpActionHandler(),
        .quit: QuitActionHandler(),
//        .restore: RestoreActionHandler(),
//        .save: SaveActionHandler(),
        .score: ScoreActionHandler(),
//        .verbose: VerboseActionHandler(),
        .wait: WaitActionHandler(),

        // TODO: Add more default handlers (Attack, Read, Eat, Drink, etc.)
    ]
}
