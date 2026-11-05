import CoreGraphics
import Testing
@testable import LetterSwitch

struct ModifierTests {
    private func flags(_ flags: CGEventFlags, device: UInt64) -> CGEventFlags {
        CGEventFlags(rawValue: flags.rawValue | device)
    }

    @Test(arguments: [
        (Modifier.rightOption, CGEventFlags.maskAlternate, UInt64(0x40)),
        (.leftOption, .maskAlternate, 0x20),
        (.rightCommand, .maskCommand, 0x10),
        (.leftCommand, .maskCommand, 0x8),
        (.rightControl, .maskControl, 0x2000),
        (.leftControl, .maskControl, 0x1),
    ])
    func matchesItsOwnKey(modifier: Modifier, flag: CGEventFlags, device: UInt64) {
        #expect(modifier.matches(flags(flag, device: device)))
    }

    @Test func rejectsTheOtherSide() {
        #expect(!Modifier.rightOption.matches(flags(.maskAlternate, device: 0x20)))
        #expect(!Modifier.leftCommand.matches(flags(.maskCommand, device: 0x10)))
    }

    @Test func rejectsBothSidesHeldTogether() {
        #expect(!Modifier.rightOption.matches(flags(.maskAlternate, device: 0x40 | 0x20)))
    }

    @Test func rejectsExtraModifiers() {
        #expect(!Modifier.rightOption.matches(flags([.maskAlternate, .maskShift], device: 0x40)))
        #expect(!Modifier.rightOption.matches(flags([.maskAlternate, .maskCommand], device: 0x40 | 0x8)))
    }

    @Test func rejectsNoModifier() {
        #expect(!Modifier.rightOption.matches([]))
    }
}
