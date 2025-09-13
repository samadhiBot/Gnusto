import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("PropertyComputationTracker Tests")
struct PropertyComputationTrackerTests {

    // MARK: - Test Data

    let itemID1: ItemID = "lamp"
    let itemID2: ItemID = "mirror"
    let locationID1: LocationID = "enchantedForest"
    let locationID2: LocationID = "magicalClearing"
    let itemPropertyID: ItemPropertyID = .brightness
    let locationPropertyID: LocationPropertyID = .description

    // MARK: - Key Generation Tests

    @Test("Item computation key format is correct")
    func itemComputationKeyFormat() {
        let key = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        #expect(key == "item:lamp:brightness")
    }

    @Test("Location computation key format is correct")
    func locationComputationKeyFormat() {
        let key = PropertyComputationTracker.key(for: locationID1, property: locationPropertyID)
        #expect(key == "location:enchantedForest:description")
    }

    @Test("Item and location keys don't conflict")
    func itemAndLocationKeysAreDistinct() {
        let itemKey = PropertyComputationTracker.key(
            for: "test", property: ItemPropertyID("attr"))
        let locationKey = PropertyComputationTracker.key(
            for: "test", property: LocationPropertyID("attr"))

        #expect(itemKey != locationKey)
        #expect(itemKey == "item:test:attr")
        #expect(locationKey == "location:test:attr")
    }

    // MARK: - TaskLocal Tracking Tests

    @Test("isActive returns false when no computations are active")
    func isActiveReturnsFalseWhenEmpty() {
        let key = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        #expect(PropertyComputationTracker.isActive(key) == false)
    }

    @Test("withTracking adds computation to active set")
    func withTrackingAddsToActiveSet() async throws {
        let key = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)

        await PropertyComputationTracker.withTracking(key) {
            #expect(PropertyComputationTracker.isActive(key) == true)
        }

        // Should be cleaned up after withTracking completes
        #expect(PropertyComputationTracker.isActive(key) == false)
    }

    @Test("withTracking handles multiple independent computations")
    func withTrackingHandlesMultipleIndependentComputations() async throws {
        let key1 = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        let key2 = PropertyComputationTracker.key(for: itemID2, property: .description)

        await PropertyComputationTracker.withTracking(key1) {
            #expect(PropertyComputationTracker.isActive(key1) == true)
            #expect(PropertyComputationTracker.isActive(key2) == false)

            await PropertyComputationTracker.withTracking(key2) {
                #expect(PropertyComputationTracker.isActive(key1) == true)
                #expect(PropertyComputationTracker.isActive(key2) == true)
            }

            #expect(PropertyComputationTracker.isActive(key1) == true)
            #expect(PropertyComputationTracker.isActive(key2) == false)
        }

        #expect(PropertyComputationTracker.isActive(key1) == false)
        #expect(PropertyComputationTracker.isActive(key2) == false)
    }

    @Test("withTracking handles nested same computation (circular dependency simulation)")
    func withTrackingHandlesNestedSameComputation() async throws {
        let key = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        var innerCallDetectedCircular = false

        await PropertyComputationTracker.withTracking(key) {
            #expect(PropertyComputationTracker.isActive(key) == true)

            // Simulate what happens in a circular dependency - check before attempting nested tracking
            if PropertyComputationTracker.isActive(key) {
                innerCallDetectedCircular = true
            }
        }

        #expect(innerCallDetectedCircular == true)
        #expect(PropertyComputationTracker.isActive(key) == false)
    }

    @Test("withTracking cleans up even when computation throws")
    func withTrackingCleansUpAfterThrow() async throws {
        let key = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)

        struct TestError: Error {}

        do {
            try await PropertyComputationTracker.withTracking(key) {
                #expect(PropertyComputationTracker.isActive(key) == true)
                throw TestError()
            }
        } catch is TestError {
            // Expected
        }

        // Should be cleaned up even after throwing
        #expect(PropertyComputationTracker.isActive(key) == false)
    }

    // MARK: - Cross-Entity Tracking Tests

    @Test("Mixed item and location tracking works correctly")
    func mixedItemLocationTracking() async throws {
        let itemKey = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        let locationKey = PropertyComputationTracker.key(
            for: locationID1, property: locationPropertyID)

        await PropertyComputationTracker.withTracking(itemKey) {
            #expect(PropertyComputationTracker.isActive(itemKey) == true)
            #expect(PropertyComputationTracker.isActive(locationKey) == false)

            await PropertyComputationTracker.withTracking(locationKey) {
                #expect(PropertyComputationTracker.isActive(itemKey) == true)
                #expect(PropertyComputationTracker.isActive(locationKey) == true)

                // This simulates what would happen in a circular dependency back to the item
                #expect(PropertyComputationTracker.isActive(itemKey) == true)
            }
        }

        #expect(PropertyComputationTracker.isActive(itemKey) == false)
        #expect(PropertyComputationTracker.isActive(locationKey) == false)
    }

    @Test("Different properties on same entity are tracked independently")
    func differentPropertiesTrackedIndependently() async throws {
        let brightnessKey = PropertyComputationTracker.key(for: itemID1, property: .brightness)
        let descriptionKey = PropertyComputationTracker.key(for: itemID1, property: .description)

        await PropertyComputationTracker.withTracking(brightnessKey) {
            #expect(PropertyComputationTracker.isActive(brightnessKey) == true)
            #expect(PropertyComputationTracker.isActive(descriptionKey) == false)

            await PropertyComputationTracker.withTracking(descriptionKey) {
                #expect(PropertyComputationTracker.isActive(brightnessKey) == true)
                #expect(PropertyComputationTracker.isActive(descriptionKey) == true)
            }
        }

        #expect(PropertyComputationTracker.isActive(brightnessKey) == false)
        #expect(PropertyComputationTracker.isActive(descriptionKey) == false)
    }

    // MARK: - TaskLocal Isolation Tests

    @Test("TaskLocal computations are isolated between concurrent tasks")
    func taskLocalIsolation() async throws {
        let key1 = PropertyComputationTracker.key(for: itemID1, property: itemPropertyID)
        let key2 = PropertyComputationTracker.key(for: itemID2, property: .description)

        async let task1: Void = PropertyComputationTracker.withTracking(key1) {
            #expect(PropertyComputationTracker.isActive(key1) == true)
            #expect(PropertyComputationTracker.isActive(key2) == false)

            // Simulate some async work
            try await Task.sleep(for: .milliseconds(50))

            #expect(PropertyComputationTracker.isActive(key1) == true)
            #expect(PropertyComputationTracker.isActive(key2) == false)
        }

        async let task2: Void = PropertyComputationTracker.withTracking(key2) {
            #expect(PropertyComputationTracker.isActive(key1) == false)
            #expect(PropertyComputationTracker.isActive(key2) == true)

            // Simulate some async work
            try await Task.sleep(for: .milliseconds(50))

            #expect(PropertyComputationTracker.isActive(key1) == false)
            #expect(PropertyComputationTracker.isActive(key2) == true)
        }

        try await task1
        try await task2

        // Both should be cleaned up
        #expect(PropertyComputationTracker.isActive(key1) == false)
        #expect(PropertyComputationTracker.isActive(key2) == false)
    }

    // MARK: - Edge Cases

    @Test("Special characters in IDs are handled correctly")
    func specialCharactersInIDsWork() async throws {
        let specialItemID = ItemID("item-with.special:characters")
        let specialPropertyID = ItemPropertyID("attr:with.special-chars")
        let key = PropertyComputationTracker.key(for: specialItemID, property: specialPropertyID)

        #expect(key == "item:item-with.special:characters:attr:with.special-chars")

        await PropertyComputationTracker.withTracking(key) {
            #expect(PropertyComputationTracker.isActive(key) == true)
        }

        #expect(PropertyComputationTracker.isActive(key) == false)
    }
}
