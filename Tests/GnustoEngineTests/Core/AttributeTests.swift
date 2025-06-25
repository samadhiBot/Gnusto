import CustomDump
import Testing

@testable import GnustoEngine

/// Test implementation of Attribute for testing purposes
private struct TestItemAttribute: Attribute {
    let id: ItemAttributeID
    let rawValue: StateValue

    init(id: ItemAttributeID, rawValue: StateValue) {
        self.id = id
        self.rawValue = rawValue
    }
}

private struct TestLocationAttribute: Attribute {
    let id: LocationAttributeID
    let rawValue: StateValue

    init(id: LocationAttributeID, rawValue: StateValue) {
        self.id = id
        self.rawValue = rawValue
    }
}

struct AttributeTests {
    
    // MARK: - Explicit Getters Tests
    
    @Test("bool getter returns correct Bool value")
    func testBoolGetter() {
        let trueBoolAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(true))
        let falseBoolAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(false))
        let nonBoolAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(trueBoolAttribute.bool == true)
        #expect(falseBoolAttribute.bool == false)
        #expect(nonBoolAttribute.bool == nil)
    }
    
    @Test("int getter returns correct Int value")
    func testIntGetter() {
        let intAttribute = TestItemAttribute(id: .size, rawValue: .int(42))
        let zeroIntAttribute = TestItemAttribute(id: .size, rawValue: .int(0))
        let negativeIntAttribute = TestItemAttribute(id: .size, rawValue: .int(-10))
        let nonIntAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(intAttribute.int == 42)
        #expect(zeroIntAttribute.int == 0)
        #expect(negativeIntAttribute.int == -10)
        #expect(nonIntAttribute.int == nil)
    }
    
    @Test("itemID getter returns correct ItemID value")
    func testItemIDGetter() {
        let itemIDAttribute = TestItemAttribute(id: .lockKey, rawValue: .itemID("key1"))
        let nonItemIDAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(itemIDAttribute.itemID == "key1")
        #expect(nonItemIDAttribute.itemID == nil)
    }

    @Test("exits getter returns correct [Direction: Exit] value")
    func testExitsGetter() {
        let exits: [Direction: Exit] = [
            .north: Exit(destination: "room1"),
            .south: Exit(destination: "room2")
        ]
        let exitsAttribute = TestLocationAttribute(
            id: .exits,
            rawValue: .exits(exits)
        )
        let emptyExitsAttribute = TestLocationAttribute(
            id: .exits,
            rawValue: .exits([:])
        )
        let nonExitsAttribute = TestLocationAttribute(
            id: .description,
            rawValue: .string("test")
        )

        #expect(exitsAttribute.exits == exits)
        #expect(emptyExitsAttribute.exits == [:])
        #expect(nonExitsAttribute.exits == nil)
    }
    
    @Test("locationID getter returns correct LocationID value")
    func testLocationIDGetter() {
        // Use a custom AttributeID for testing since there’s no built-in one for LocationID
        let customLocationAttr = ItemAttributeID("currentLocation")
        let locationIDAttribute = TestItemAttribute(id: customLocationAttr, rawValue: .locationID("room1"))
        let nonLocationIDAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(locationIDAttribute.locationID == "room1")
        #expect(nonLocationIDAttribute.locationID == nil)
    }
    
    @Test("parentEntity getter returns correct ParentEntity value")
    func testParentEntityGetter() {
        let playerParentAttribute = TestItemAttribute(id: .parentEntity, rawValue: .parentEntity(.player))
        let locationParentAttribute = TestItemAttribute(id: .parentEntity, rawValue: .parentEntity(.location("room1")))
        let itemParentAttribute = TestItemAttribute(id: .parentEntity, rawValue: .parentEntity(.item("container1")))
        let nowhereParentAttribute = TestItemAttribute(id: .parentEntity, rawValue: .parentEntity(.nowhere))
        let nonParentAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(playerParentAttribute.parentEntity == ParentEntity.player)
        #expect(locationParentAttribute.parentEntity == ParentEntity.location("room1"))
        #expect(itemParentAttribute.parentEntity == ParentEntity.item("container1"))
        #expect(nowhereParentAttribute.parentEntity == ParentEntity.nowhere)
        #expect(nonParentAttribute.parentEntity == nil)
    }
    
    @Test("string getter returns correct String value")
    func testStringGetter() {
        let stringAttribute = TestItemAttribute(id: .description, rawValue: .string("Hello, world!"))
        let emptyStringAttribute = TestItemAttribute(id: .description, rawValue: .string(""))
        let nonStringAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(true))
        
        #expect(stringAttribute.string == "Hello, world!")
        #expect(emptyStringAttribute.string == "")
        #expect(nonStringAttribute.string == nil)
    }
    
    @Test("strings getter returns correct Set<String> value")
    func testStringsGetter() {
        let stringSet: Set<String> = ["apple", "banana", "cherry"]
        let stringsAttribute = TestItemAttribute(id: .synonyms, rawValue: .stringSet(stringSet))
        let emptyStringsAttribute = TestItemAttribute(id: .synonyms, rawValue: .stringSet([]))
        let nonStringsAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(stringsAttribute.strings == stringSet)
        #expect(emptyStringsAttribute.strings == [])
        #expect(nonStringsAttribute.strings == nil)
    }
    
    // MARK: - Implicit Getters Tests
    
    @Test("implicit Bool getter returns correct value")
    func testImplicitBoolGetter() {
        let trueBoolAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(true))
        let falseBoolAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(false))
        let nonBoolAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let trueResult: Bool = trueBoolAttribute.get()
        let falseResult: Bool = falseBoolAttribute.get()
        let nonBoolResult: Bool = nonBoolAttribute.get()
        
        #expect(trueResult == true)
        #expect(falseResult == false)
        #expect(nonBoolResult == false) // Default value for non-Bool
    }
    
    @Test("implicit Int? getter returns correct value")
    func testImplicitIntGetter() {
        let intAttribute = TestItemAttribute(id: .size, rawValue: .int(42))
        let nonIntAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let intResult: Int? = intAttribute.get()
        let nonIntResult: Int? = nonIntAttribute.get()
        
        #expect(intResult == 42)
        #expect(nonIntResult == nil)
    }
    
    @Test("implicit ItemID? getter returns correct value")
    func testImplicitItemIDGetter() {
        let itemIDAttribute = TestItemAttribute(id: .lockKey, rawValue: .itemID("key1"))
        let nonItemIDAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let itemIDResult: ItemID? = itemIDAttribute.get()
        let nonItemIDResult: ItemID? = nonItemIDAttribute.get()
        
        #expect(itemIDResult == "key1")
        #expect(nonItemIDResult == nil)
    }
    
    @Test("implicit Set<ItemID>? getter returns correct value")
    func testImplicitItemIDsGetter() {
        let itemIDSet: Set<ItemID> = ["item1", "item2"]
        let itemIDsAttribute = TestLocationAttribute(
            id: .localGlobals,
            rawValue: .itemIDSet(itemIDSet)
        )
        let nonItemIDsAttribute = TestLocationAttribute(
            id: .description,
            rawValue: .string("test")
        )

        let itemIDsResult: Set<ItemID>? = itemIDsAttribute.get()
        let nonItemIDsResult: Set<ItemID>? = nonItemIDsAttribute.get()
        
        #expect(itemIDsResult == itemIDSet)
        #expect(nonItemIDsResult == nil)
    }
    
    @Test("implicit [Direction: Exit]? getter returns correct value")
    func testImplicitExitsGetter() {
        let exits: [Direction: Exit] = [.north: Exit(destination: "room1")]
        let exitsAttribute = TestLocationAttribute(
            id: .exits,
            rawValue: .exits(exits)
        )
        let nonExitsAttribute = TestLocationAttribute(
            id: .description,
            rawValue: .string("test")
        )

        let exitsResult: [Direction: Exit]? = exitsAttribute.get()
        let nonExitsResult: [Direction: Exit]? = nonExitsAttribute.get()
        
        #expect(exitsResult == exits)
        #expect(nonExitsResult == nil)
    }
    
    @Test("implicit LocationID? getter returns correct value")
    func testImplicitLocationIDGetter() {
        let customLocationAttr = ItemAttributeID("currentLocation")
        let locationIDAttribute = TestItemAttribute(id: customLocationAttr, rawValue: .locationID("room1"))
        let nonLocationIDAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let locationIDResult: LocationID? = locationIDAttribute.get()
        let nonLocationIDResult: LocationID? = nonLocationIDAttribute.get()
        
        #expect(locationIDResult == "room1")
        #expect(nonLocationIDResult == nil)
    }
    
    @Test("implicit ParentEntity? getter returns correct value")
    func testImplicitParentEntityGetter() {
        let parentAttribute = TestItemAttribute(id: .parentEntity, rawValue: .parentEntity(.player))
        let nonParentAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let parentResult: ParentEntity? = parentAttribute.get()
        let nonParentResult: ParentEntity? = nonParentAttribute.get()
        
        #expect(parentResult == ParentEntity.player)
        #expect(nonParentResult == nil)
    }
    
    @Test("implicit String? getter returns correct value")
    func testImplicitStringGetter() {
        let stringAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        let nonStringAttribute = TestItemAttribute(id: .isOn, rawValue: .bool(true))
        
        let stringResult: String? = stringAttribute.get()
        let nonStringResult: String? = nonStringAttribute.get()
        
        #expect(stringResult == "test")
        #expect(nonStringResult == nil)
    }
    
    @Test("implicit Set<String>? getter returns correct value")
    func testImplicitStringsGetter() {
        let stringSet: Set<String> = ["test1", "test2"]
        let stringsAttribute = TestItemAttribute(id: .synonyms, rawValue: .stringSet(stringSet))
        let nonStringsAttribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        let stringsResult: Set<String>? = stringsAttribute.get()
        let nonStringsResult: Set<String>? = nonStringsAttribute.get()
        
        #expect(stringsResult == stringSet)
        #expect(nonStringsResult == nil)
    }
    
    // MARK: - Edge Cases and Special Values
    
    @Test("undefined StateValue returns appropriate defaults")
    func testUndefinedStateValue() {
        let undefinedAttribute = TestItemAttribute(id: .description, rawValue: .undefined)
        
        // undefined returns nil for most getters, except int which returns Int.min
        #expect(undefinedAttribute.bool == nil)
        #expect(undefinedAttribute.int == Int.min) // undefined returns Int.min for int
        #expect(undefinedAttribute.itemID == nil)
        #expect(undefinedAttribute.itemIDs == nil)
        #expect(undefinedAttribute.exits == nil)
        #expect(undefinedAttribute.locationID == nil)
        #expect(undefinedAttribute.parentEntity == nil)
        #expect(undefinedAttribute.string == nil)
        #expect(undefinedAttribute.strings == nil)
        
        // Test implicit getters with undefined
        let boolResult: Bool = undefinedAttribute.get()
        let intResult: Int? = undefinedAttribute.get()
        let stringResult: String? = undefinedAttribute.get()
        
        #expect(boolResult == false) // Default for Bool
        #expect(intResult == Int.min) // Int? getter returns Int.min for undefined
        #expect(stringResult == nil)
    }
    
    @Test("entityReferenceSet with nil value returns empty set")
    func testEntityReferenceSetWithNil() {
        let customPronounAttr = ItemAttributeID("pronounReference_it")
        let nilEntityRefAttribute = TestItemAttribute(id: customPronounAttr, rawValue: .entityReferenceSet(nil))
        
        #expect(nilEntityRefAttribute.itemIDs == [])
        
        let result: Set<ItemID>? = nilEntityRefAttribute.get()
        #expect(result == [])
    }
    
    @Test("entityReferenceSet with actual set returns correct value")
    func testEntityReferenceSetWithValue() {
        let entityRefs: Set<EntityReference> = [.item("item1"), .item("item2")]
        let customPronounAttr = ItemAttributeID("pronounReference_them")
        let entityRefAttribute = TestItemAttribute(id: customPronounAttr, rawValue: .entityReferenceSet(entityRefs))
        
        // Note: This test checks that entityReferenceSet returns the EntityReference set, not ItemID set
        // The itemIDs getter should return nil since this is not an itemIDSet
        #expect(entityRefAttribute.itemIDs == nil)
        
        // But we can check the underlying value directly
        if case .entityReferenceSet(let refs) = entityRefAttribute.rawValue {
            #expect(refs == entityRefs)
        } else {
            #expect(Bool(false), "Expected entityReferenceSet case")
        }
    }
    
    // MARK: - Attribute Protocol Conformance
    
    @Test("Attribute protocol requirements are satisfied")
    func testAttributeProtocolConformance() {
        let attribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(attribute.id == .description)
        #expect(attribute.rawValue == .string("test"))
        
        // Test that we can create an attribute from id and rawValue
        let recreatedAttribute = TestItemAttribute(id: attribute.id, rawValue: attribute.rawValue)
        #expect(recreatedAttribute.id == attribute.id)
        #expect(recreatedAttribute.rawValue == attribute.rawValue)
    }
    
    @Test("Attribute Equatable conformance works correctly")
    func testAttributeEquatable() {
        let attribute1 = TestItemAttribute(id: .description, rawValue: .string("test"))
        let attribute2 = TestItemAttribute(id: .description, rawValue: .string("test"))
        let attribute3 = TestItemAttribute(id: .description, rawValue: .string("different"))
        let attribute4 = TestItemAttribute(id: .name, rawValue: .string("test"))
        
        #expect(attribute1 == attribute2)
        #expect(attribute1 != attribute3)
        #expect(attribute1 != attribute4)
    }
    
    @Test("Attribute Identifiable conformance works correctly")
    func testAttributeIdentifiable() {
        let attribute = TestItemAttribute(id: .description, rawValue: .string("test"))
        
        #expect(attribute.id == .description)
    }
} 
