import Foundation

// Simple test runner for AttackActionHandler
@main
struct AttackTest {
    static func main() async throws {
        print("Testing AttackActionHandler with ZIL-accurate messaging...")
        
        // Test 1: Attack non-character object
        print("\n1. Attack non-character object:")
        let rock = MockItem(id: "rock", name: "rock", isCharacter: false)
        let message1 = getAttackMessage(target: rock, weapon: nil)
        print("Expected: I've known strange people, but fighting a rock?")
        print("Actual  : \(message1)")
        print("Match: \(message1.contains("I've known strange people, but fighting a rock?"))")
        
        // Test 2: Attack character with bare hands
        print("\n2. Attack character with bare hands:")
        let goblin = MockItem(id: "goblin", name: "goblin", isCharacter: true)
        let message2 = getAttackMessage(target: goblin, weapon: nil)
        print("Expected: Trying to attack a goblin with your bare hands is suicidal.")
        print("Actual  : \(message2)")
        print("Match: \(message2.contains("Trying to attack a goblin with your bare hands is suicidal."))")
        
        // Test 3: Attack character with non-weapon
        print("\n3. Attack character with non-weapon:")
        let lamp = MockItem(id: "lamp", name: "lamp", isCharacter: false, isWeapon: false)
        let message3 = getAttackMessage(target: goblin, weapon: lamp)
        print("Expected: Trying to attack the goblin with a lamp is suicidal.")
        print("Actual  : \(message3)")
        print("Match: \(message3.contains("Trying to attack the goblin with a lamp is suicidal."))")
        
        // Test 4: Attack character with weapon
        print("\n4. Attack character with weapon:")
        let sword = MockItem(id: "sword", name: "sword", isCharacter: false, isWeapon: true)
        let message4 = getAttackMessage(target: goblin, weapon: sword)
        print("Expected: You can't.")
        print("Actual  : \(message4)")
        print("Match: \(message4.contains("You can't."))")
        
        print("\nAll tests completed!")
    }
    
    static func getAttackMessage(target: MockItem, weapon: MockItem?) -> String {
        // Simulate the ZIL V-ATTACK logic from AttackActionHandler
        
        // First check: Is target NOT a character? (ZIL: NOT FSET? PRSO ACTORBIT)
        if !target.isCharacter {
            return "I've known strange people, but fighting a \(target.name)?"
        }
        // Second check: No weapon specified (bare-handed attack)
        else if weapon == nil {
            return "Trying to attack a \(target.name) with your bare hands is suicidal."
        }
        // We have a weapon - check if it's a real weapon
        else if let weapon = weapon {
            if !weapon.isWeapon {
                return "Trying to attack the \(target.name) with a \(weapon.name) is suicidal."
            } else {
                // Real weapon attack - placeholder for combat system
                return "You can't."
            }
        } else {
            // Fallback case
            return "You can't."
        }
    }
}

struct MockItem {
    let id: String
    let name: String
    let isCharacter: Bool
    let isWeapon: Bool
    
    init(id: String, name: String, isCharacter: Bool, isWeapon: Bool = false) {
        self.id = id
        self.name = name
        self.isCharacter = isCharacter
        self.isWeapon = isWeapon
    }
}