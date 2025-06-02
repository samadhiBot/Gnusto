import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("ActionResponse Tests")
struct ActionResponseTests {

    // MARK: - Test Data

    let testItemID: ItemID = "testItem"
    let testContainerID: ItemID = "testContainer"
    let testSurfaceID: ItemID = "testSurface"
    let testKeyID: ItemID = "testKey"
    let testLockID: ItemID = "testLock"
    let testLocationID: LocationID = "testLocation"
    let testAttributeID: AttributeID = "testAttribute"
    let testGlobalID: GlobalID = "testGlobal"

    // MARK: - CustomStringConvertible Tests

    @Test("containerIsClosed description")
    func testContainerIsClosedDescription() {
        let response = ActionResponse.containerIsClosed(testItemID)
        let expected = ".containerIsClosed(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("containerIsOpen description")
    func testContainerIsOpenDescription() {
        let response = ActionResponse.containerIsOpen(testItemID)
        let expected = ".containerIsOpen(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("custom description")
    func testCustomDescription() {
        let customMessage = "This is a custom error message."
        let response = ActionResponse.custom(customMessage)
        let expected = ".custom(\(customMessage))"
        #expect(response.description == expected)
    }

    @Test("directionIsBlocked description with reason")
    func testDirectionIsBlockedWithReasonDescription() {
        let reason = "The door is locked."
        let response = ActionResponse.directionIsBlocked(reason)
        let expected = ".directionIsBlocked(\(reason))"
        #expect(response.description == expected)
    }

    @Test("directionIsBlocked description without reason")
    func testDirectionIsBlockedWithoutReasonDescription() {
        let response = ActionResponse.directionIsBlocked(nil)
        let expected = ".directionIsBlocked()"
        #expect(response.description == expected)
    }

    @Test("internalEngineError description")
    func testInternalEngineErrorDescription() {
        let errorMessage = "Something went wrong internally."
        let response = ActionResponse.internalEngineError(errorMessage)
        let expected = ".internalEngineError(\(errorMessage))"
        #expect(response.description == expected)
    }

    @Test("invalidDirection description")
    func testInvalidDirectionDescription() {
        let response = ActionResponse.invalidDirection
        let expected = ".invalidDirection"
        #expect(response.description == expected)
    }

    @Test("invalidIndirectObject description with object name")
    func testInvalidIndirectObjectWithNameDescription() {
        let objectName = "the mysterious box"
        let response = ActionResponse.invalidIndirectObject(objectName)
        let expected = ".invalidIndirectObject(\(objectName))"
        #expect(response.description == expected)
    }

    @Test("invalidIndirectObject description without object name")
    func testInvalidIndirectObjectWithoutNameDescription() {
        let response = ActionResponse.invalidIndirectObject(nil)
        let expected = ".invalidIndirectObject()"
        #expect(response.description == expected)
    }

    @Test("invalidValue description")
    func testInvalidValueDescription() {
        let valueMessage = "Expected integer, got string."
        let response = ActionResponse.invalidValue(valueMessage)
        let expected = ".invalidValue(\(valueMessage))"
        #expect(response.description == expected)
    }

    @Test("itemAlreadyClosed description")
    func testItemAlreadyClosedDescription() {
        let response = ActionResponse.itemAlreadyClosed(testItemID)
        let expected = ".itemAlreadyClosed(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemAlreadyOpen description")
    func testItemAlreadyOpenDescription() {
        let response = ActionResponse.itemAlreadyOpen(testItemID)
        let expected = ".itemAlreadyOpen(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemIsAlreadyWorn description")
    func testItemIsAlreadyWornDescription() {
        let response = ActionResponse.itemIsAlreadyWorn(testItemID)
        let expected = ".itemIsAlreadyWorn(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemIsLocked description")
    func testItemIsLockedDescription() {
        let response = ActionResponse.itemIsLocked(testItemID)
        let expected = ".itemIsLocked(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemIsNotWorn description")
    func testItemIsNotWornDescription() {
        let response = ActionResponse.itemIsNotWorn(testItemID)
        let expected = ".itemIsNotWorn(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemIsUnlocked description")
    func testItemIsUnlockedDescription() {
        let response = ActionResponse.itemIsUnlocked(testItemID)
        let expected = ".itemIsUnlocked(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotAccessible description")
    func testItemNotAccessibleDescription() {
        let response = ActionResponse.itemNotAccessible(testItemID)
        let expected = ".itemNotAccessible(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotClosable description")
    func testItemNotClosableDescription() {
        let response = ActionResponse.itemNotClosable(testItemID)
        let expected = ".itemNotClosable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotDroppable description")
    func testItemNotDroppableDescription() {
        let response = ActionResponse.itemNotDroppable(testItemID)
        let expected = ".itemNotDroppable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotEdible description")
    func testItemNotEdibleDescription() {
        let response = ActionResponse.itemNotEdible(testItemID)
        let expected = ".itemNotEdible(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotHeld description")
    func testItemNotHeldDescription() {
        let response = ActionResponse.itemNotHeld(testItemID)
        let expected = ".itemNotHeld(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotInContainer description")
    func testItemNotInContainerDescription() {
        let response = ActionResponse.itemNotInContainer(
            item: testItemID,
            container: testContainerID
        )
        let expected = """
            .itemNotInContainer(
               item: \(testItemID),
               container: \(testContainerID)
            )
            """
        #expect(response.description == expected)
    }

    @Test("itemNotLockable description")
    func testItemNotLockableDescription() {
        let response = ActionResponse.itemNotLockable(testItemID)
        let expected = ".itemNotLockable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotOnSurface description")
    func testItemNotOnSurfaceDescription() {
        let response = ActionResponse.itemNotOnSurface(
            item: testItemID,
            surface: testSurfaceID
        )
        let expected = """
            .itemNotOnSurface(
               item: \(testItemID),
               surface: \(testSurfaceID)
            )
            """
        #expect(response.description == expected)
    }

    @Test("itemNotOpenable description")
    func testItemNotOpenableDescription() {
        let response = ActionResponse.itemNotOpenable(testItemID)
        let expected = ".itemNotOpenable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotReadable description")
    func testItemNotReadableDescription() {
        let response = ActionResponse.itemNotReadable(testItemID)
        let expected = ".itemNotReadable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotRemovable description")
    func testItemNotRemovableDescription() {
        let response = ActionResponse.itemNotRemovable(testItemID)
        let expected = ".itemNotRemovable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotTakable description")
    func testItemNotTakableDescription() {
        let response = ActionResponse.itemNotTakable(testItemID)
        let expected = ".itemNotTakable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotUnlockable description")
    func testItemNotUnlockableDescription() {
        let response = ActionResponse.itemNotUnlockable(testItemID)
        let expected = ".itemNotUnlockable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemNotWearable description")
    func testItemNotWearableDescription() {
        let response = ActionResponse.itemNotWearable(testItemID)
        let expected = ".itemNotWearable(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("itemTooLargeForContainer description")
    func testItemTooLargeForContainerDescription() {
        let response = ActionResponse.itemTooLargeForContainer(
            item: testItemID,
            container: testContainerID
        )
        let expected = """
            .itemTooLargeForContainer(
               item: \(testItemID),
               container: \(testContainerID)
            )
            """
        #expect(response.description == expected)
    }

    @Test("playerCannotCarryMore description")
    func testPlayerCannotCarryMoreDescription() {
        let response = ActionResponse.playerCannotCarryMore
        let expected = ".playerCannotCarryMore"
        #expect(response.description == expected)
    }

    @Test("prerequisiteNotMet description")
    func testPrerequisiteNotMetDescription() {
        let prerequisiteMessage = "You need a key to unlock this door."
        let response = ActionResponse.prerequisiteNotMet(prerequisiteMessage)
        let expected = ".prerequisiteNotMet(\(prerequisiteMessage))"
        #expect(response.description == expected)
    }

    @Test("roomIsDark description")
    func testRoomIsDarkDescription() {
        let response = ActionResponse.roomIsDark
        let expected = ".roomIsDark"
        #expect(response.description == expected)
    }

    @Test("stateValidationFailed description")
    func testStateValidationFailedDescription() {
        let stateChange = StateChange(
            entityID: .item(testItemID),
            attribute: .itemAttribute(testAttributeID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )
        let actualOldValue: StateValue = .bool(true)

        let response = ActionResponse.stateValidationFailed(
            change: stateChange,
            actualOldValue: actualOldValue
        )

        expectNoDifference(response.description, """
            .stateValidationFailed(
               change: 
                  StateChange(
                     entityID: .item(.testItem)
                     attribute: .itemAttribute(.testAttribute)
                     oldValue: false
                     newValue: true
                  ),
               actualOldValue: true
            )
            """)
    }

    @Test("stateValidationFailed description with nil actualOldValue")
    func testStateValidationFailedWithNilActualOldValueDescription() {
        let stateChange = StateChange(
            entityID: .item(testItemID),
            attribute: .itemAttribute(testAttributeID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )

        let response = ActionResponse.stateValidationFailed(
            change: stateChange,
            actualOldValue: nil
        )

        expectNoDifference(response.description, """
            .stateValidationFailed(
               change: 
                  StateChange(
                     entityID: .item(.testItem)
                     attribute: .itemAttribute(.testAttribute)
                     oldValue: false
                     newValue: true
                  ),
               actualOldValue: nil
            )
            """)
    }

    @Test("targetIsNotAContainer description")
    func testTargetIsNotAContainerDescription() {
        let response = ActionResponse.targetIsNotAContainer(testItemID)
        let expected = ".targetIsNotAContainer(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("targetIsNotASurface description")
    func testTargetIsNotASurfaceDescription() {
        let response = ActionResponse.targetIsNotASurface(testItemID)
        let expected = ".targetIsNotASurface(\(testItemID))"
        #expect(response.description == expected)
    }

    @Test("toolMissing description")
    func testToolMissingDescription() {
        let toolName = "a crowbar"
        let response = ActionResponse.toolMissing(toolName)
        let expected = ".toolMissing(\(toolName))"
        #expect(response.description == expected)
    }

    @Test("unknownEntity description with item")
    func testUnknownEntityWithItemDescription() {
        let entityReference = EntityReference.item(testItemID)
        let response = ActionResponse.unknownEntity(entityReference)
        let expected = ".unknownEntity(\(entityReference))"
        #expect(response.description == expected)
    }

    @Test("unknownEntity description with location")
    func testUnknownEntityWithLocationDescription() {
        let entityReference = EntityReference.location(testLocationID)
        let response = ActionResponse.unknownEntity(entityReference)
        let expected = ".unknownEntity(\(entityReference))"
        #expect(response.description == expected)
    }

    @Test("unknownEntity description with player")
    func testUnknownEntityWithPlayerDescription() {
        let entityReference = EntityReference.player
        let response = ActionResponse.unknownEntity(entityReference)
        let expected = ".unknownEntity(\(entityReference))"
        #expect(response.description == expected)
    }

    @Test("unknownVerb description")
    func testUnknownVerbDescription() {
        let verbWord = "flibber"
        let response = ActionResponse.unknownVerb(verbWord)
        let expected = ".unknownVerb(\(verbWord))"
        #expect(response.description == expected)
    }

    @Test("wrongKey description")
    func testWrongKeyDescription() {
        let response = ActionResponse.wrongKey(
            keyID: testKeyID,
            lockID: testLockID
        )
        expectNoDifference(
            response.description,
            """
            .wrongKey(
               key: .testKey,
               lock: .testLock
            )
            """
        )
    }

    // MARK: - Edge Cases

    @Test("custom description with empty string")
    func testCustomDescriptionWithEmptyString() {
        let response = ActionResponse.custom("")
        let expected = ".custom()"
        #expect(response.description == expected)
    }

    @Test("custom description with special characters")
    func testCustomDescriptionWithSpecialCharacters() {
        let customMessage = "Error: \"Something\" went wrong! (Code: 42)"
        let response = ActionResponse.custom(customMessage)
        let expected = ".custom(\(customMessage))"
        #expect(response.description == expected)
    }

    @Test("prerequisiteNotMet description with multiline string")
    func testPrerequisiteNotMetWithMultilineString() {
        let multilineMessage = """
            You need to complete several tasks:
            1. Find the key
            2. Unlock the door
            3. Enter the room
            """
        let response = ActionResponse.prerequisiteNotMet(multilineMessage)
        let expected = ".prerequisiteNotMet(\(multilineMessage))"
        #expect(response.description == expected)
    }

    @Test("internalEngineError description with very long message")
    func testInternalEngineErrorWithLongMessage() {
        let longMessage = String(repeating: "This is a very long error message. ", count: 10)
        let response = ActionResponse.internalEngineError(longMessage)
        let expected = ".internalEngineError(\(longMessage))"
        #expect(response.description == expected)
    }

    // MARK: - Consistency Tests

    @Test("All single-parameter ItemID cases follow consistent format")
    func testSingleItemIDCasesConsistency() {
        let testCases: [(ActionResponse, String)] = [
            (.containerIsClosed(testItemID), ".containerIsClosed(\(testItemID))"),
            (.containerIsOpen(testItemID), ".containerIsOpen(\(testItemID))"),
            (.itemAlreadyClosed(testItemID), ".itemAlreadyClosed(\(testItemID))"),
            (.itemAlreadyOpen(testItemID), ".itemAlreadyOpen(\(testItemID))"),
            (.itemIsAlreadyWorn(testItemID), ".itemIsAlreadyWorn(\(testItemID))"),
            (.itemIsLocked(testItemID), ".itemIsLocked(\(testItemID))"),
            (.itemIsNotWorn(testItemID), ".itemIsNotWorn(\(testItemID))"),
            (.itemIsUnlocked(testItemID), ".itemIsUnlocked(\(testItemID))"),
            (.itemNotAccessible(testItemID), ".itemNotAccessible(\(testItemID))"),
            (.itemNotClosable(testItemID), ".itemNotClosable(\(testItemID))"),
            (.itemNotDroppable(testItemID), ".itemNotDroppable(\(testItemID))"),
            (.itemNotEdible(testItemID), ".itemNotEdible(\(testItemID))"),
            (.itemNotHeld(testItemID), ".itemNotHeld(\(testItemID))"),
            (.itemNotLockable(testItemID), ".itemNotLockable(\(testItemID))"),
            (.itemNotOpenable(testItemID), ".itemNotOpenable(\(testItemID))"),
            (.itemNotReadable(testItemID), ".itemNotReadable(\(testItemID))"),
            (.itemNotRemovable(testItemID), ".itemNotRemovable(\(testItemID))"),
            (.itemNotTakable(testItemID), ".itemNotTakable(\(testItemID))"),
            (.itemNotUnlockable(testItemID), ".itemNotUnlockable(\(testItemID))"),
            (.itemNotWearable(testItemID), ".itemNotWearable(\(testItemID))"),
            (.targetIsNotAContainer(testItemID), ".targetIsNotAContainer(\(testItemID))"),
            (.targetIsNotASurface(testItemID), ".targetIsNotASurface(\(testItemID))"),
        ]

        for (response, expectedDescription) in testCases {
            #expect(response.description == expectedDescription, "Inconsistent format for \(response)")
        }
    }

    @Test("All two-parameter ItemID cases follow consistent multiline format")
    func testTwoItemIDCasesConsistency() {
        expectNoDifference(
            ActionResponse.itemNotInContainer(
                item: testItemID,
                container: testContainerID
            ).description,
            """
            .itemNotInContainer(
               item: .testItem,
               container: .testContainer
            )
            """
        )

        expectNoDifference(
            ActionResponse.itemNotOnSurface(
                item: testItemID,
                surface: testSurfaceID
            ).description,
            """
            .itemNotOnSurface(
               item: .testItem,
               surface: .testSurface
            )
            """
        )

        expectNoDifference(
            ActionResponse.itemTooLargeForContainer(
                item: testItemID,
                container: testContainerID
            ).description,
            """
            .itemTooLargeForContainer(
               item: .testItem,
               container: .testContainer
            )
            """
        )
        expectNoDifference(
            ActionResponse.wrongKey(
                keyID: testKeyID,
                lockID: testLockID
            ).description,
            """
            .wrongKey(
               key: .testKey,
               lock: .testLock
            )
            """
        )
    }

    @Test("All no-parameter cases follow consistent format")
    func testNoParameterCasesConsistency() {
        let testCases: [(ActionResponse, String)] = [
            (.invalidDirection, ".invalidDirection"),
            (.playerCannotCarryMore, ".playerCannotCarryMore"),
            (.roomIsDark, ".roomIsDark"),
        ]
        
        for (response, expectedDescription) in testCases {
            #expect(response.description == expectedDescription, "Inconsistent format for \(response)")
        }
    }
} 
