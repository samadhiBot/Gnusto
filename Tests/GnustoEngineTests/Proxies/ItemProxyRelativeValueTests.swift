import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ItemProxy Relative Value Tests")
struct ItemProxyRelativeValueTests {

    // MARK: - Relative Value Tests

    @Test("relativeValue calculates correctly with varied item values")
    func testRelativeValueCalculation() async throws {
        // Given: Items with varied values
        let lowValueItem = Item(
            id: "lowItem",
            .name("low value item"),
            .isTakable,
            .value(5),
            .in(.startRoom)
        )

        let mediumValueItem = Item(
            id: "mediumItem",
            .name("medium value item"),
            .isTakable,
            .value(50),
            .in(.startRoom)
        )

        let highValueItem = Item(
            id: "highItem",
            .name("high value item"),
            .isTakable,
            .value(100),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lowValueItem, mediumValueItem, highValueItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative values
        let lowItem = try await engine.item("lowItem")
        let mediumItem = try await engine.item("mediumItem")
        let highItem = try await engine.item("highItem")

        let lowRelativeValue = try await lowItem.relativeValue
        let mediumRelativeValue = try await mediumItem.relativeValue
        let highRelativeValue = try await highItem.relativeValue

        // Then: Values should use smart distribution
        // With values 5, 50, 100, the low item (5) actually falls into worthless range
        #expect(lowRelativeValue == 0.0)
        #expect(mediumRelativeValue == 0.459572006940428)
        #expect(highRelativeValue == 1.0000000000000002)
    }

    @Test("relativeValue handles edge case with single item")
    func testRelativeValueWithSingleItem() async throws {
        // Given: Only one item
        let (engine, _) = await GameEngine.test(
            blueprint: MinimalGame(items: Lab.axe)
        )

        // When: Getting relative value
        let item = try await engine.item("axe")
        let relativeValue = try await item.relativeValue

        // Then: Should return 0.5 (default for edge cases)
        #expect(relativeValue == 0.5)
    }

    @Test("relativeValue handles items with identical values")
    func testRelativeValueWithIdenticalValues() async throws {
        // Given: Multiple items with same value
        let item1 = Item(
            id: "item1",
            .name("first item"),
            .isTakable,
            .value(25),
            .in(.startRoom)
        )

        let item2 = Item(
            id: "item2",
            .name("second item"),
            .isTakable,
            .value(25),
            .in(.startRoom)
        )

        let item3 = Item(
            id: "item3",
            .name("third item"),
            .isTakable,
            .value(25),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item1, item2, item3
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative values
        let firstItem = try await engine.item("item1")
        let relativeValue = try await firstItem.relativeValue

        // Then: Should return 0.5 (default when all values equal)
        #expect(relativeValue == 0.5)
    }

    @Test("relativeValue filters out extreme outliers")
    func testRelativeValueWithOutliers() async throws {
        // Given: Items with normal range plus extreme outliers
        let item1 = Item(
            id: "normal1",
            .name("normal item 1"),
            .isTakable,
            .value(10),
            .in(.startRoom)
        )

        let item2 = Item(
            id: "normal2",
            .name("normal item 2"),
            .isTakable,
            .value(20),
            .in(.startRoom)
        )

        let item3 = Item(
            id: "normal3",
            .name("normal item 3"),
            .isTakable,
            .value(30),
            .in(.startRoom)
        )

        let item4 = Item(
            id: "normal4",
            .name("normal item 4"),
            .isTakable,
            .value(40),
            .in(.startRoom)
        )

        let item5 = Item(
            id: "normal5",
            .name("normal item 5"),
            .isTakable,
            .value(50),
            .in(.startRoom)
        )

        let extremeOutlier = Item(
            id: "outlier",
            .name("extreme outlier"),
            .isTakable,
            .value(1_000_000),  // Extreme outlier
            .in(.startRoom)
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .isTakable,
            .value(25),  // Should be low-medium in normal range
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item1, item2, item3, item4, item5, extremeOutlier, testItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative value of test item
        let item = try await engine.item("testItem")
        let relativeValue = try await item.relativeValue

        // Then: Should be low in normal range (outlier filtered out)
        #expect(relativeValue == 0.3945054945054945)
        #expect(try await item.relativeValueCategory == .low)
    }

    // MARK: - Relative Weapon Damage Tests

    @Test("relativeWeaponDamage calculates correctly with varied damage values")
    func testRelativeWeaponDamageCalculation() async throws {
        // Given: Items with varied weapon damage
        let weakWeapon = Item(
            id: "weakWeapon",
            .name("weak dagger"),
            .isTakable,
            .isWeapon,
            .damage(2),
            .in(.startRoom)
        )

        let mediumWeapon = Item(
            id: "mediumWeapon",
            .name("standard sword"),
            .isTakable,
            .isWeapon,
            .damage(10),
            .in(.startRoom)
        )

        let strongWeapon = Item(
            id: "strongWeapon",
            .name("mighty axe"),
            .isTakable,
            .isWeapon,
            .damage(20),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: weakWeapon, mediumWeapon, strongWeapon
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative weapon damage
        let weak = try await engine.item("weakWeapon")
        let medium = try await engine.item("mediumWeapon")
        let strong = try await engine.item("strongWeapon")

        let weakRelativeDamage = try await weak.relativeWeaponDamage
        let mediumRelativeDamage = try await medium.relativeWeaponDamage
        let strongRelativeDamage = try await strong.relativeWeaponDamage

        // Then: Damage should use smart distribution, clustering middle values
        // With damage 2, 10, 20, algorithm prevents artificial spreading to extremes
        #expect(weakRelativeDamage == 0)
        #expect(mediumRelativeDamage == 0.4402930402930403)
        #expect(strongRelativeDamage == 0.78)
    }

    @Test("relativeWeaponDamage handles non-weapon items")
    func testRelativeWeaponDamageWithNonWeapons() async throws {
        // Given: Mix of weapons and non-weapons
        let weapon = Item(
            id: "weapon",
            .name("sword"),
            .isTakable,
            .isWeapon,
            .damage(15),
            .in(.startRoom)
        )

        let nonWeapon = Item(
            id: "nonWeapon",
            .name("book"),
            .isTakable,
            // No damage property - defaults to 0
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: weapon, nonWeapon
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative weapon damage
        let weaponItem = try await engine.item("weapon")
        let bookItem = try await engine.item("nonWeapon")

        let weaponRelativeDamage = try await weaponItem.relativeWeaponDamage
        let bookRelativeDamage = try await bookItem.relativeWeaponDamage

        // Then: Weapon should be high, book should be low
        #expect(abs(weaponRelativeDamage - 0.78) < 0.01)
        #expect(bookRelativeDamage == 0.0)
    }

    // MARK: - Edge Case Tests

    @Test("relative value calculation with wide range distribution")
    func testRelativeValueWithWideDistribution() async throws {
        // Given: Items with a wide distribution of values
        // Create 9 items with values from 0 to 80 (step of 10)
        let item0 = Item(
            id: "item0",
            .name("item 0"),
            .isTakable,
            .value(0),
            .in(.startRoom)
        )
        let item1 = Item(
            id: "item1",
            .name("item 1"),
            .isTakable,
            .value(10),
            .in(.startRoom)
        )
        let item2 = Item(
            id: "item2",
            .name("item 2"),
            .isTakable,
            .value(20),
            .in(.startRoom)
        )
        let item3 = Item(
            id: "item3",
            .name("item 3"),
            .isTakable,
            .value(30),
            .in(.startRoom)
        )
        let item4 = Item(
            id: "item4",
            .name("item 4"),
            .isTakable,
            .value(40),
            .in(.startRoom)
        )
        let item5 = Item(
            id: "item5",
            .name("item 5"),
            .isTakable,
            .value(50),
            .in(.startRoom)
        )
        let item6 = Item(
            id: "item6",
            .name("item 6"),
            .isTakable,
            .value(60),
            .in(.startRoom)
        )
        let item7 = Item(
            id: "item7",
            .name("item 7"),
            .isTakable,
            .value(70),
            .in(.startRoom)
        )
        let item8 = Item(
            id: "item8",
            .name("item 8"),
            .isTakable,
            .value(80),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: item0, item1, item2, item3, item4, item5, item6, item7, item8
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting relative values for different percentiles
        let lowItem = try await engine.item("item1")  // Value 10, should be low
        let midItem = try await engine.item("item4")  // Value 40, should be medium
        let highItem = try await engine.item("item7")  // Value 70, should be high

        let lowRelative = try await lowItem.relativeValue
        let midRelative = try await midItem.relativeValue
        let highRelative = try await highItem.relativeValue

        // Then: Should distribute with smart scaling that prevents artificial extremes
        // With values 0-80, the algorithm uses meaningful distribution
        #expect(abs(lowRelative - 0.232) < 0.05)
        #expect(abs(midRelative - 0.477) < 0.01)
        #expect(abs(highRelative - 0.733) < 0.05)

    }

    // MARK: - RoughValue Integration Tests

    @Test("roughValue uses higher of relativeValue and relativeWeaponDamage")
    func testRoughValueUsesHigherRelative() async throws {
        // Given: Items with different value vs damage profiles
        // High value, low damage item
        let valuableItem = Item(
            id: "valuableItem",
            .name("golden goblet"),
            .isTakable,
            .value(100),
            .damage(20),
            .in(.startRoom)
        )

        // Low value, high damage item
        let weaponItem = Item(
            id: "weaponItem",
            .name("rusty sword"),
            .isTakable,
            .value(5),
            .damage(30),
            .in(.startRoom)
        )

        // Medium value, medium damage item
        let balancedItem = Item(
            id: "startItem",
            .name("balanced item"),
            .isTakable,
            .value(25),
            .damage(25),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: valuableItem, weaponItem, balancedItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting rough values
        let valuable = try await engine.item("valuableItem")
        let weapon = try await engine.item("weaponItem")
        let balanced = try await engine.item("startItem")

        let valuableRough = try await valuable.roughValue
        let weaponRough = try await weapon.roughValue
        let balancedRough = try await balanced.roughValue

        // Then: Should use the higher relative value
        // Valuable item should be high due to value
        #expect(valuableRough == .priceless)
        // Weapon should be high due to smart distribution
        #expect(weaponRough == .high)
        // Balanced item should be medium
        #expect(balancedRough == .medium)
    }

    @Test("roughValue handles edge cases correctly")
    func testRoughValueEdgeCases() async throws {
        // Given: Single item
        let singleItem = Item(
            id: "startItem",
            .name("only item"),
            .isTakable,
            .value(42),
            .damage(10),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: singleItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting rough value for single item
        let item = try await engine.item("startItem")
        let roughValue = try await item.roughValue

        // Then: Should return medium (both relatives return 0.5)
        #expect(roughValue == .medium)
    }

    // MARK: - Category Convenience Property Tests

    @Test("relativeValueCategory returns correct categories")
    func testRelativeValueCategory() async throws {
        // Given: Items with varied values
        let lowValueItem = Item(
            id: "lowItem",
            .name("low value item"),
            .isTakable,
            .value(5),
            .in(.startRoom)
        )

        let mediumValueItem = Item(
            id: "mediumItem",
            .name("medium value item"),
            .isTakable,
            .value(50),
            .in(.startRoom)
        )

        let highValueItem = Item(
            id: "highItem",
            .name("high value item"),
            .isTakable,
            .value(100),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lowValueItem, mediumValueItem, highValueItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting category values
        let lowItem = try await engine.item("lowItem")
        let mediumItem = try await engine.item("mediumItem")
        let highItem = try await engine.item("highItem")

        let lowCategory = try await lowItem.relativeValueCategory
        let mediumCategory = try await mediumItem.relativeValueCategory
        let highCategory = try await highItem.relativeValueCategory

        // Then: Categories should reflect smart distribution (reserving extremes for outliers)
        // With values 5, 50, 100, the low value (5) is actually worthless relative to the range
        #expect(lowCategory == .worthless)
        #expect(mediumCategory == .medium)
        #expect(highCategory == .priceless)
    }

    @Test("relativeWeaponDamageCategory returns correct categories")
    func testRelativeWeaponDamageCategory() async throws {
        // Given: Items with varied weapon damage
        let weakWeapon = Item(
            id: "weakWeapon",
            .name("weak dagger"),
            .isTakable,
            .isWeapon,
            .damage(2),
            .in(.startRoom)
        )

        let mediumWeapon = Item(
            id: "mediumWeapon",
            .name("standard sword"),
            .isTakable,
            .isWeapon,
            .damage(10),
            .in(.startRoom)
        )

        let strongWeapon = Item(
            id: "strongWeapon",
            .name("mighty axe"),
            .isTakable,
            .isWeapon,
            .damage(20),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: weakWeapon, mediumWeapon, strongWeapon
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting category values
        let weak = try await engine.item("weakWeapon")
        let medium = try await engine.item("mediumWeapon")
        let strong = try await engine.item("strongWeapon")

        let weakCategory = try await weak.relativeWeaponDamageCategory
        let mediumCategory = try await medium.relativeWeaponDamageCategory
        let strongCategory = try await strong.relativeWeaponDamageCategory

        // Then: Categories should reflect smart distribution
        // With damage 2, 10, 20, the weak weapon (2) is actually worthless relative to the range
        #expect(weakCategory == .worthless)
        #expect(mediumCategory == .medium)
        #expect(strongCategory == .high)
    }

    @Test("five category system distributes correctly")
    func testFiveCategoryDistribution() async throws {
        // Given: 25 items with evenly distributed values to test all 5 categories
        // Create 25 items with values from 0 to 240 (step of 10)
        // This should distribute as: 0-4 = worthless, 5-9 = low, 10-14 = medium, 15-19 = high, 20-24 = priceless
        // Create 10 items with evenly distributed values to test all 5 categories
        let item0 = Item(
            id: ItemID("item0"), .name("item 0"), .isTakable, .value(0), .in(.startRoom))
        let item1 = Item(
            id: ItemID("item1"), .name("item 1"), .isTakable, .value(10), .in(.startRoom)
        )
        let item2 = Item(
            id: ItemID("item2"), .name("item 2"), .isTakable, .value(20), .in(.startRoom)
        )
        let item3 = Item(
            id: ItemID("item3"), .name("item 3"), .isTakable, .value(30), .in(.startRoom)
        )
        let item4 = Item(
            id: ItemID("item4"), .name("item 4"), .isTakable, .value(40), .in(.startRoom)
        )
        let item5 = Item(
            id: ItemID("item5"), .name("item 5"), .isTakable, .value(50), .in(.startRoom)
        )
        let item6 = Item(
            id: ItemID("item6"), .name("item 6"), .isTakable, .value(60), .in(.startRoom)
        )
        let item7 = Item(
            id: ItemID("item7"), .name("item 7"), .isTakable, .value(70), .in(.startRoom)
        )
        let item8 = Item(
            id: ItemID("item8"), .name("item 8"), .isTakable, .value(80), .in(.startRoom)
        )
        let item9 = Item(
            id: ItemID("item9"), .name("item 9"), .isTakable, .value(90), .in(.startRoom)
        )

        let game = MinimalGame(
            items: item0, item1, item2, item3, item4, item5, item6, item7, item8, item9
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting categories for items in different percentile ranges
        let worthlessItem = try await engine.item(ItemID("item0"))  // Should be in 0-20th percentile
        let lowItem = try await engine.item(ItemID("item2"))  // Should be in 20-40th percentile
        let mediumItem = try await engine.item(ItemID("item4"))  // Should be in 40-60th percentile
        let highItem = try await engine.item(ItemID("item7"))  // Should be in 60-80th percentile
        let pricelessItem = try await engine.item(ItemID("item9"))  // Should be in 80-100th percentile

        let worthlessCategory = try await worthlessItem.relativeValueCategory
        let lowCategory = try await lowItem.relativeValueCategory
        let mediumCategory = try await mediumItem.relativeValueCategory
        let highCategory = try await highItem.relativeValueCategory
        let pricelessCategory = try await pricelessItem.relativeValueCategory

        // Then: All 5 categories should be represented correctly
        #expect(worthlessCategory == .worthless)
        #expect(lowCategory == .low)
        #expect(mediumCategory == .medium)
        #expect(highCategory == .high)
        #expect(pricelessCategory == .priceless)
    }

    @Test("roughValue integrates correctly with 5-category system")
    func testRoughValueWith5Categories() async throws {
        // Given: Items that should fall into different categories based on max of value/damage
        // Create 7 base items for comparison
        let base1 = Item(
            id: ItemID("base1"), .name("base 1"), .value(5), .damage(3), .in(.startRoom))
        let base2 = Item(
            id: ItemID("base2"), .name("base 2"), .value(10), .damage(6), .in(.startRoom)
        )
        let base3 = Item(
            id: ItemID("base3"), .name("base 3"), .value(15), .damage(9), .in(.startRoom)
        )
        let base4 = Item(
            id: ItemID("base4"), .name("base 4"), .value(20), .damage(12),
            .in(.startRoom))
        let base5 = Item(
            id: ItemID("base5"), .name("base 5"), .value(25), .damage(15),
            .in(.startRoom))
        let base6 = Item(
            id: ItemID("base6"), .name("base 6"), .value(30), .damage(18),
            .in(.startRoom))
        let base7 = Item(
            id: ItemID("base7"), .name("base 7"), .value(35), .damage(21),
            .in(.startRoom))

        // Test items with different value/damage profiles
        let worthlessItem = Item(
            id: "worthlessTest",
            .name("worthless test item"),
            .value(2),  // Very low value
            .damage(1),  // Very low damage
            .in(.startRoom)
        )

        let pricelessItem = Item(
            id: "pricelessTest",
            .name("priceless test item"),
            .value(100),  // Very high value
            .damage(50),  // Very high damage
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: base1, base2, base3, base4, base5, base6, base7, worthlessItem, pricelessItem
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: Getting rough values
        let worthless = try await engine.item("worthlessTest")
        let priceless = try await engine.item("pricelessTest")

        let worthlessRough = try await worthless.roughValue
        let pricelessRough = try await priceless.roughValue

        // Then: Should use the 5-category system correctly
        #expect(worthlessRough == .worthless)
        #expect(pricelessRough == .priceless)
    }
}

extension Double {
    fileprivate static var oneThird: Double {
        1.0 / 3.0
    }

    fileprivate static var twoThirds: Double {
        2.0 / 3.0
    }
}
