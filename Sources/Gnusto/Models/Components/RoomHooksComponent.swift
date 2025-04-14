import Foundation

/// Provides lifecycle hooks for room events
public struct RoomHooksComponent: Component {
    public static let type: ComponentType = .roomHooks

    /// Hook called when a player enters this room
    /// - Returns: Array of effects to apply
    public let onEnter: (@Sendable (World) -> [Effect])?

    /// Hook called before any action is processed in this room
    /// - Returns: Array of effects to apply or nil to let the action proceed normally
    public let beforeAction: (@Sendable (Action, World) -> [Effect]?)?

    /// Hook called after any action is processed in this room
    /// - Returns: Array of additional effects to apply
    public let afterAction: (@Sendable (Action, World) -> [Effect])?

    /// Initialize with optional hooks
    public init(
        onEnter: (@Sendable (World) -> [Effect])? = nil,
        beforeAction: (@Sendable (Action, World) -> [Effect]?)? = nil,
        afterAction: (@Sendable (Action, World) -> [Effect])? = nil
    ) {
        self.onEnter = onEnter
        self.beforeAction = beforeAction
        self.afterAction = afterAction
    }
}

extension Object {
    /// Adds room hooks to a room object.
    ///
    /// - Parameters:
    ///   - onEnter: Hook called when the player enters this room
    ///   - beforeAction: Hook called before any action is processed in this room
    ///   - afterAction: Hook called after any action is processed in this room
    /// - Returns: The updated room object.
    @discardableResult
    public func withRoomHooks(
        onEnter: (@Sendable (World) -> [Effect])? = nil,
        beforeAction: (@Sendable (Action, World) -> [Effect]?)? = nil,
        afterAction: (@Sendable (Action, World) -> [Effect])? = nil
    ) -> Object {
        add(
            RoomHooksComponent(
                onEnter: onEnter,
                beforeAction: beforeAction,
                afterAction: afterAction
            )
        )
        return self
    }
}
