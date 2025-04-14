import Foundation
import Testing

@testable import Gnusto

@Suite
struct EventTests {
    @Test
    func testScheduleEvent() throws {
        // Create a test world with a player
        let world = World()

        // Schedule an event
        let result = world.scheduleEvent("testEvent", delay: 3)

        // Verify event was scheduled
        #expect(result == true)
        #expect(world.isEventScheduled("testEvent") == true)

        // Get the event
        let event = world.getEvent("testEvent")
        #expect(event != nil)
        #expect(event?.turnsRemaining == 3)
        #expect(event?.isRepeating == false)
    }

    @Test
    func testCancelEvent() throws {
        // Create a test world with a player
        let world = World()

        // Schedule an event
        world.scheduleEvent("testEvent", delay: 3)

        // Cancel the event
        let result = world.cancelEvent("testEvent")

        // Verify event was cancelled
        #expect(result == true)
        #expect(world.isEventScheduled("testEvent") == false)
    }

    @Test
    func testProcessEvents() throws {
        // Create a test world with a player
        let world = World()

        // Schedule multiple events
        world.scheduleEvent("event1", delay: 1)
        world.scheduleEvent("event2", delay: 2)
        world.scheduleEvent("event3", delay: 3)

        // Process events for first turn
        let firstTurnEvents = world.processEvents()
        #expect(firstTurnEvents.count == 1)
        #expect(firstTurnEvents[0] == "event1")
        #expect(world.isEventScheduled("event1") == false)
        #expect(world.isEventScheduled("event2") == true)
        #expect(world.isEventScheduled("event3") == true)

        // Process events for second turn
        let secondTurnEvents = world.processEvents()
        #expect(secondTurnEvents.count == 1)
        #expect(secondTurnEvents[0] == "event2")
        #expect(world.isEventScheduled("event1") == false)
        #expect(world.isEventScheduled("event2") == false)
        #expect(world.isEventScheduled("event3") == true)
    }

    @Test
    func testRepeatingEvents() throws {
        // Create a test world with a player
        let world = World()

        // Schedule a repeating event
        world.scheduleEvent("repeatingEvent", delay: 2, isRepeating: true)

        // Process first cycle
        let firstCycleEvents = world.processEvents()
        #expect(firstCycleEvents.count == 0)

        // Process second cycle (event should trigger)
        let secondCycleEvents = world.processEvents()
        #expect(secondCycleEvents.count == 1)
        #expect(secondCycleEvents[0] == "repeatingEvent")
        #expect(world.isEventScheduled("repeatingEvent") == true)

        // Process third cycle (event should not trigger again yet)
        let thirdCycleEvents = world.processEvents()
        #expect(thirdCycleEvents.count == 0)

        // Process fourth cycle (event should trigger again)
        let fourthCycleEvents = world.processEvents()
        #expect(fourthCycleEvents.count == 1)
        #expect(fourthCycleEvents[0] == "repeatingEvent")
    }

    @Test
    func testActionDispatcherWithEvents() throws {
        // Create a test world with a player
        let world = World()

        // Schedule events
        world.scheduleEvent("testEvent", delay: 1)

        // Create a dispatcher with registry
        let dispatcher = ActionDispatcher(
            commandRegistry: CommandRegistry.default
        )

        // Add an event handler
        var eventTriggered = false
        dispatcher.registerEventHandler("testEvent") { _ -> [Effect] in // Explicitly type return
            eventTriggered = true
            return [.showText("Event triggered!")]
        }

        // Process turn events
        let effects = dispatcher.processTurnEvents(in: world)

        // Check that the event handler was called
        #expect(eventTriggered == true)
        #expect(effects.count == 1)
        // Check the effect type safely
        guard effects.count == 1, case .showText(let output) = effects[0] else {
            // Use TestFailure for better error reporting in tests
            throw TestFailure("Expected a single .showText effect, got \(effects)")
        }
        #expect(output == "Event triggered!")
    }
}
