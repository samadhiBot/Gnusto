import Foundation

// MARK: - Action Handler Registry

extension GameEngine {
    /// **Default Handlers**: The engine provides standard handlers for common verbs
    /// like `take`, `drop`, `look`, etc. Games can override these via custom handlers
    /// in the `GameBlueprint`.
    ///
    /// The order of handlers in this array matters for verb conflicts - more specific
    /// syntax-based handlers should come before simple verb-based handlers to ensure
    /// proper precedence during command matching.
    ///
    /// In debug builds, includes additional debugging handlers for development support.
    public static var defaultActionHandlers: [ActionHandler] {
        let handlers: [ActionHandler] = [
            AskActionHandler(),
            AttackActionHandler(),
            BlowActionHandler(),
            BreatheActionHandler(),
            BriefActionHandler(),
            TurnOnActionHandler(),
            BurnActionHandler(),
            ChompActionHandler(),
            ClimbActionHandler(),
            ClimbOnActionHandler(),
            CloseActionHandler(),
            CryActionHandler(),
            CurseActionHandler(),
            CutActionHandler(),
            DanceActionHandler(),
            DeflateActionHandler(),
            DigActionHandler(),
            DrinkActionHandler(),
            DropActionHandler(),
            EatActionHandler(),
            EmptyActionHandler(),
            ExtinguishActionHandler(),
            EnterActionHandler(),
            ExamineActionHandler(),
            FillActionHandler(),
            FindActionHandler(),
            GiveActionHandler(),
            GoActionHandler(),
            HelpActionHandler(),
            InflateActionHandler(),
            InsertActionHandler(),
            InventoryActionHandler(),
            JumpActionHandler(),
            KickActionHandler(),
            KissActionHandler(),
            KnockActionHandler(),
            LaughActionHandler(),
            ListenActionHandler(),
            LockActionHandler(),
            LookActionHandler(),
            LookInsideActionHandler(),
            LookUnderActionHandler(),
            MoveActionHandler(),
            NibbleActionHandler(),
            OpenActionHandler(),
            PourActionHandler(),
            PullActionHandler(),
            PushActionHandler(),
            PutOnActionHandler(),
            QuitActionHandler(),
            RaiseActionHandler(),
            ReadActionHandler(),
            RemoveActionHandler(),
            RestartActionHandler(),
            RestoreActionHandler(),
            RubActionHandler(),
            SaveActionHandler(),
            ScoreActionHandler(),
            ScriptActionHandler(),
            ShakeActionHandler(),
            SingActionHandler(),
            SmellActionHandler(),
            SqueezeActionHandler(),
            TakeActionHandler(),
            TasteActionHandler(),
            TellActionHandler(),
            ThinkActionHandler(),
            ThrowActionHandler(),
            TieActionHandler(),
            TouchActionHandler(),
            TurnOffActionHandler(),
            TurnActionHandler(),
            UnlockActionHandler(),
            UnscriptActionHandler(),
            VerboseActionHandler(),
            WaitActionHandler(),
            WaveActionHandler(),
            WearActionHandler(),
            XyzzyActionHandler(),
            YellActionHandler(),
            YesNoQuestionHandler(),
        ]

        #if DEBUG
            return handlers + [DebugActionHandler()]
        #else
            return handlers
        #endif
    }
}
