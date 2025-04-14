import Testing
import Gnusto

@Test
func testObjectProperties() throws {
    let game = TestGame()
    let world = try game.createWorld()

    // Test lantern properties
    guard let lantern = world.find("lantern") else {
        throw TestFailure("Failed to get lantern")
    }
    guard let lanternDesc = lantern.find(DescriptionComponent.self) else {
        throw TestFailure("Failed to get lantern description")
    }
    #expect(lanternDesc.name == "brass lantern")
    #expect(lanternDesc.synonyms.contains("lamp") == true)

    guard let lanternObj = lantern.find(ObjectComponent.self) else {
        throw TestFailure("Failed to get lantern object")
    }
    #expect(lanternObj.flags.contains(.takeable) == true)

    guard let lightSourceComponent = lantern.find(LightSourceComponent.self) else {
        throw TestFailure("Failed to get LightSourceComponent from lantern")
    }
    #expect(lightSourceComponent.isOn == false)

    // Test chest properties
    guard let chest = world.find("chest") else {
        throw TestFailure("Failed to get chest")
    }
    guard let chestContainer = chest.find(ContainerComponent.self) else {
        throw TestFailure("Failed to get chest container component")
    }
    #expect(chestContainer.isOpen == false)
    #expect(chestContainer.isTransparent == false)
}
