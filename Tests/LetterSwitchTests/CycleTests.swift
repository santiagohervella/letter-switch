import Testing
@testable import LetterSwitch

struct CycleTests {
    let arc = TestApp(1, "Arc")
    let ghostty = TestApp(2, "Ghostty")
    let glide = TestApp(3, "Glide")
    let github = TestApp(4, "GitHub Desktop")

    private func press(_ key: Character, _ recent: inout [TestApp], _ cycle: inout Cycle<TestApp>?) -> TestApp? {
        cycle = Cycle.next(key: key, recent: recent, previous: cycle, assignments: KeyAssignments())
        guard let target = cycle?.target else { return nil }
        recent.removeAll { $0 == target }
        recent.insert(target, at: 0)
        return target
    }

    @Test func goesToTheMostRecentMatchingApp() {
        var recent = [arc, glide, ghostty]
        var cycle: Cycle<TestApp>?
        #expect(press("g", &recent, &cycle) == glide)
    }

    @Test func goesToTheNextMatchingAppWhenOneIsFocused() {
        var recent = [ghostty, arc, glide]
        var cycle: Cycle<TestApp>?
        #expect(press("g", &recent, &cycle) == glide)
    }

    @Test func staysOnTheOnlyMatchingApp() {
        var recent = [ghostty, arc]
        var cycle: Cycle<TestApp>?
        #expect(press("g", &recent, &cycle) == ghostty)
    }

    @Test func repeatedPressesVisitEveryMatchingApp() {
        var recent = [arc, ghostty, glide, github]
        var cycle: Cycle<TestApp>?
        let visited = (0..<4).compactMap { _ in press("g", &recent, &cycle) }
        #expect(visited == [ghostty, glide, github, ghostty])
    }

    @Test func switchingAwayStartsAFreshCycle() {
        var recent = [arc, ghostty, glide, github]
        var cycle: Cycle<TestApp>?
        #expect(press("g", &recent, &cycle) == ghostty)
        #expect(press("g", &recent, &cycle) == glide)
        #expect(press("a", &recent, &cycle) == arc)
        #expect(press("g", &recent, &cycle) == glide)
    }

    @Test func skipsTerminatedApps() {
        let quitGlide = TestApp(3, "Glide", isTerminated: true)
        var recent = [arc, quitGlide, ghostty]
        var cycle: Cycle<TestApp>?
        #expect(press("g", &recent, &cycle) == ghostty)
    }

    @Test func returnsNothingWithoutAMatchingApp() {
        var recent = [arc, ghostty]
        var cycle: Cycle<TestApp>?
        #expect(press("z", &recent, &cycle) == nil)
    }
}
