/// Provides localized messages for the Gnusto Interactive Fiction Engine.
///
/// The `MessageProvider` system serves two primary purposes:
/// 1. **Internationalization**: Supporting multiple languages for the engine and games
/// 2. **Developer Customization**: Allowing game developers to customize default engine responses
///
/// Game developers can provide custom message providers via their `GameBlueprint` to override
/// default engine messages, customize response tone, or provide full localization support.
///
/// ## Message Keys
///
/// Messages are identified by `MessageKey` enum cases that correspond to specific engine
/// scenarios (e.g., `.roomIsDark`, `.itemNotTakable`, `.unknownVerb`). Each key may have
/// associated parameters for dynamic content (e.g., item names, directions).
///
/// ## Default Implementation
///
/// The engine provides `StandardMessageProvider` with traditional IF responses in English.
/// Games can subclass this provider to override specific messages while inheriting defaults
/// for others, or implement the protocol entirely for complete customization.
///
/// ## Example Usage
///
/// ```swift
/// // Custom message provider for a horror game
/// class HorrorMessageProvider: StandardMessageProvider {
///     override func message(for key: MessageKey) -> String {
///         switch key {
///         case .roomIsDark:
///             "The suffocating darkness presses in around you."
///         case .itemNotTakable(let item):
///             "Something prevents you from touching \(item)."
///         default:
///             super.message(for: key)
///         }
///     }
/// }
/// ```
public protocol MessageProvider: Sendable {
    /// Returns a localized message for the given key.
    ///
    /// Implementations should provide appropriate messages for all `MessageKey` cases.
    /// If a specific message is not available, providers should fall back to English
    /// defaults rather than returning empty strings.
    ///
    /// - Parameter key: The `MessageKey` identifying the message to retrieve
    /// - Returns: A localized message string, with any parameters interpolated
    func message(for key: MessageKey) -> String

    /// The language/locale identifier for this provider (e.g., "en", "es", "fr")
    var languageCode: String { get }
}
