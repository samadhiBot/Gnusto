import Foundation

/// Character consciousness levels affecting awareness and ability to act.
///
/// This enum represents different levels of consciousness from fully alert to dead.
/// Consciousness affects perception, initiative, and what actions a character can take.
public enum ConsciousnessLevel: String, Codable, Sendable, Hashable, CaseIterable {
    /// Fully alert and aware of surroundings.
    ///
    /// The character can take all normal actions and has full perception.
    case alert

    /// Tired and less alert than usual.
    ///
    /// The character has reduced perception and initiative but can still act normally.
    /// Common after exhaustion or late at night.
    case drowsy

    /// Naturally sleeping but can be awakened.
    ///
    /// The character cannot take actions or perceive their surroundings while asleep,
    /// but loud noises or physical contact will wake them.
    case asleep

    /// Knocked out or in a faint.
    ///
    /// The character cannot act or perceive anything. They may wake up naturally
    /// after time or when healed/helped by others.
    case unconscious

    /// Deep unconsciousness from severe trauma or magic.
    ///
    /// More serious than unconscious - the character is very difficult to wake
    /// and may require magical healing or extended medical care.
    case coma

    /// No longer alive.
    ///
    /// The character cannot act, perceive, or be awakened by normal means.
    /// May potentially be resurrected through powerful magic.
    case dead
}

// MARK: - Consciousness Level Properties

extension ConsciousnessLevel {
    /// Whether the character can take actions.
    public var canAct: Bool {
        switch self {
        case .alert, .drowsy: true
        case .asleep, .unconscious, .coma, .dead: false
        }
    }

    /// Whether the character can perceive their surroundings.
    public var canPerceive: Bool {
        switch self {
        case .alert, .drowsy: true
        case .asleep, .unconscious, .coma, .dead: false
        }
    }

    /// Whether the character can be easily awakened.
    public var canBeAwakened: Bool {
        switch self {
        case .alert, .drowsy: false  // Already awake
        case .asleep: true  // Normal sleep
        case .unconscious: true  // With help/healing
        case .coma: false  // Requires significant intervention
        case .dead: false  // Cannot be awakened normally
        }
    }

    /// Modifier to perception rolls based on consciousness level.
    public var perceptionModifier: Int {
        switch self {
        case .alert: 0
        case .drowsy: -2
        case .asleep, .unconscious, .coma, .dead: -999  // Cannot perceive
        }
    }

    /// Modifier to initiative rolls based on consciousness level.
    public var initiativeModifier: Int {
        switch self {
        case .alert: 0
        case .drowsy: -1
        case .asleep, .unconscious, .coma, .dead: -999  // Cannot act
        }
    }
}
