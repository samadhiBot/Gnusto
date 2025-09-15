import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ObjectCondition Tests")
struct ObjectConditionTests {

    // MARK: - Initialization Tests

    @Test("ObjectCondition initializes with raw value")
    func testInitialization() {
        let condition = ObjectCondition(rawValue: 42)
        #expect(condition.rawValue == 42)
    }

    @Test("ObjectCondition initializes with zero raw value")
    func testZeroInitialization() {
        let condition = ObjectCondition(rawValue: 0)
        #expect(condition.rawValue == 0)
        #expect(condition == .none)
    }

    // MARK: - Static Property Tests

    @Test("ObjectCondition.none has correct raw value")
    func testNoneProperty() {
        #expect(ObjectCondition.none.rawValue == 0)
        #expect(ObjectCondition.none.isEmpty)
    }

    @Test("ObjectCondition.held has correct raw value")
    func testHeldProperty() {
        #expect(ObjectCondition.held.rawValue == 1 << 0)
        #expect(ObjectCondition.held.rawValue == 1)
    }

    @Test("ObjectCondition.inRoom has correct raw value")
    func testInRoomProperty() {
        #expect(ObjectCondition.inRoom.rawValue == 1 << 1)
        #expect(ObjectCondition.inRoom.rawValue == 2)
    }

    @Test("ObjectCondition.onGround has correct raw value")
    func testOnGroundProperty() {
        #expect(ObjectCondition.onGround.rawValue == 1 << 2)
        #expect(ObjectCondition.onGround.rawValue == 4)
    }

    @Test("ObjectCondition.allowsMultiple has correct raw value")
    func testAllowsMultipleProperty() {
        #expect(ObjectCondition.allowsMultiple.rawValue == 1 << 4)
        #expect(ObjectCondition.allowsMultiple.rawValue == 16)
    }

    @Test("ObjectCondition.person has correct raw value")
    func testPersonProperty() {
        #expect(ObjectCondition.person.rawValue == 1 << 5)
        #expect(ObjectCondition.person.rawValue == 32)
    }

    @Test("ObjectCondition.container has correct raw value")
    func testContainerProperty() {
        #expect(ObjectCondition.container.rawValue == 1 << 6)
        #expect(ObjectCondition.container.rawValue == 64)
    }

    @Test("ObjectCondition.worn has correct raw value")
    func testWornProperty() {
        #expect(ObjectCondition.worn.rawValue == 1 << 7)
        #expect(ObjectCondition.worn.rawValue == 128)
    }

    // MARK: - OptionSet Behavior Tests

    @Test("ObjectCondition supports union operations")
    func testUnionOperations() {
        let combined = ObjectCondition.held.union(.inRoom)
        #expect(combined.rawValue == 3)  // 1 + 2
        #expect(combined.contains(.held))
        #expect(combined.contains(.inRoom))
        #expect(!combined.contains(.onGround))
    }

    @Test("ObjectCondition supports intersection operations")
    func testIntersectionOperations() {
        let first: ObjectCondition = [.held, .inRoom, .container]
        let second: ObjectCondition = [.inRoom, .container, .worn]
        let intersection = first.intersection(second)

        #expect(intersection.contains(.inRoom))
        #expect(intersection.contains(.container))
        #expect(!intersection.contains(.held))
        #expect(!intersection.contains(.worn))
    }

    @Test("ObjectCondition supports subtraction operations")
    func testSubtractionOperations() {
        let full: ObjectCondition = [.held, .inRoom, .container]
        let result = full.subtracting(.inRoom)

        #expect(result.contains(.held))
        #expect(result.contains(.container))
        #expect(!result.contains(.inRoom))
    }

    @Test("ObjectCondition supports symmetricDifference operations")
    func testSymmetricDifferenceOperations() {
        let first: ObjectCondition = [.held, .inRoom]
        let second: ObjectCondition = [.inRoom, .container]
        let difference = first.symmetricDifference(second)

        #expect(difference.contains(.held))
        #expect(difference.contains(.container))
        #expect(!difference.contains(.inRoom))
    }

    // MARK: - Array Literal and Collection Tests

    @Test("ObjectCondition can be created with array literal")
    func testArrayLiteralCreation() {
        let conditions: ObjectCondition = [.held, .inRoom, .container]

        #expect(conditions.contains(.held))
        #expect(conditions.contains(.inRoom))
        #expect(conditions.contains(.container))
        #expect(!conditions.contains(.worn))
    }

    @Test("ObjectCondition empty array literal creates none")
    func testEmptyArrayLiteral() {
        let conditions: ObjectCondition = []
        #expect(conditions == .none)
        #expect(conditions.isEmpty)
    }

    @Test("ObjectCondition supports contains check")
    func testContainsCheck() {
        let conditions: ObjectCondition = [.held, .container]

        #expect(conditions.contains(.held))
        #expect(conditions.contains(.container))
        #expect(!conditions.contains(.inRoom))
        #expect(!conditions.contains(.worn))
    }

    // MARK: - Insertion and Removal Tests

    @Test("ObjectCondition supports insert operations")
    func testInsertOperations() {
        var conditions: ObjectCondition = [.held]

        let (inserted, member) = conditions.insert(.inRoom)
        #expect(inserted)
        #expect(member == .inRoom)
        #expect(conditions.contains(.held))
        #expect(conditions.contains(.inRoom))

        // Insert existing member
        let (notInserted, existingMember) = conditions.insert(.held)
        #expect(!notInserted)
        #expect(existingMember == .held)
    }

    @Test("ObjectCondition supports remove operations")
    func testRemoveOperations() {
        var conditions: ObjectCondition = [.held, .inRoom, .container]

        let removed = conditions.remove(.inRoom)
        #expect(removed == .inRoom)
        #expect(conditions.contains(.held))
        #expect(conditions.contains(.container))
        #expect(!conditions.contains(.inRoom))

        // Remove non-existing member
        let notRemoved = conditions.remove(.worn)
        #expect(notRemoved == nil)
    }

    // MARK: - Mutation Operator Tests

    @Test("ObjectCondition supports formUnion mutation")
    func testFormUnionMutation() {
        var conditions: ObjectCondition = [.held]
        conditions.formUnion([.inRoom, .container])

        #expect(conditions.contains(.held))
        #expect(conditions.contains(.inRoom))
        #expect(conditions.contains(.container))
    }

    @Test("ObjectCondition supports formIntersection mutation")
    func testFormIntersectionMutation() {
        var conditions: ObjectCondition = [.held, .inRoom, .container]
        conditions.formIntersection([.inRoom, .container, .worn])

        #expect(!conditions.contains(.held))
        #expect(conditions.contains(.inRoom))
        #expect(conditions.contains(.container))
        #expect(!conditions.contains(.worn))
    }

    @Test("ObjectCondition supports formSymmetricDifference mutation")
    func testFormSymmetricDifferenceMutation() {
        var conditions: ObjectCondition = [.held, .inRoom]
        conditions.formSymmetricDifference([.inRoom, .container])

        #expect(conditions.contains(.held))
        #expect(!conditions.contains(.inRoom))
        #expect(conditions.contains(.container))
    }

    @Test("ObjectCondition supports subtract mutation")
    func testSubtractMutation() {
        var conditions: ObjectCondition = [.held, .inRoom, .container]
        conditions.subtract([.inRoom, .worn])

        #expect(conditions.contains(.held))
        #expect(!conditions.contains(.inRoom))
        #expect(conditions.contains(.container))
    }

    // MARK: - Equality Tests

    @Test("ObjectCondition equality works correctly")
    func testEquality() {
        let first: ObjectCondition = [.held, .inRoom]
        let second: ObjectCondition = [.inRoom, .held]  // Different order
        let third: ObjectCondition = [.held, .container]

        #expect(first == second)
        #expect(first != third)
        #expect(ObjectCondition.none == ObjectCondition(rawValue: 0))
    }

    // MARK: - Complex Combination Tests

    @Test("ObjectCondition complex combinations work correctly")
    func testComplexCombinations() {
        let playerInventoryConditions: ObjectCondition = [.held, .worn]
        let roomConditions: ObjectCondition = [.inRoom, .onGround]
        let containerConditions: ObjectCondition = [.container, .allowsMultiple]

        let allConditions = playerInventoryConditions.union(roomConditions).union(
            containerConditions)

        #expect(allConditions.contains(.held))
        #expect(allConditions.contains(.worn))
        #expect(allConditions.contains(.inRoom))
        #expect(allConditions.contains(.onGround))
        #expect(allConditions.contains(.container))
        #expect(allConditions.contains(.allowsMultiple))
        #expect(!allConditions.contains(.person))
    }

    @Test("ObjectCondition handles all static properties in combination")
    func testAllStaticPropertiesCombination() {
        let allConditions: ObjectCondition = [
            .held, .inRoom, .onGround, .allowsMultiple,
            .person, .container, .worn,
        ]

        // Check each individual condition
        #expect(allConditions.contains(.held))
        #expect(allConditions.contains(.inRoom))
        #expect(allConditions.contains(.onGround))
        #expect(allConditions.contains(.allowsMultiple))
        #expect(allConditions.contains(.person))
        #expect(allConditions.contains(.container))
        #expect(allConditions.contains(.worn))

        // Check expected raw value (sum of all powers of 2)
        let expectedRawValue = 1 + 2 + 4 + 16 + 32 + 64 + 128  // 247
        #expect(allConditions.rawValue == expectedRawValue)
    }

    // MARK: - Edge Case Tests

    @Test("ObjectCondition handles maximum raw value")
    func testMaximumRawValue() {
        let maxCondition = ObjectCondition(rawValue: Int.max)
        #expect(maxCondition.rawValue == Int.max)
    }

    @Test("ObjectCondition handles negative raw value")
    func testNegativeRawValue() {
        let negativeCondition = ObjectCondition(rawValue: -1)
        #expect(negativeCondition.rawValue == -1)
    }

    @Test("ObjectCondition isEmpty works correctly")
    func testIsEmptyProperty() {
        #expect(ObjectCondition.none.isEmpty)
        #expect(ObjectCondition([]).isEmpty)
        #expect(!ObjectCondition.held.isEmpty)
        #expect(![ObjectCondition.held, .inRoom].isEmpty)
    }
}
