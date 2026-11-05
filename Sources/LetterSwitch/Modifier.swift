import CoreGraphics

enum Modifier: String, Decodable {
    case rightOption = "right_option"
    case leftOption = "left_option"
    case rightCommand = "right_command"
    case leftCommand = "left_command"
    case rightControl = "right_control"
    case leftControl = "left_control"

    private enum DeviceMask {
        static let leftControl: UInt64 = 0x1
        static let leftCommand: UInt64 = 0x8
        static let rightCommand: UInt64 = 0x10
        static let leftOption: UInt64 = 0x20
        static let rightOption: UInt64 = 0x40
        static let rightControl: UInt64 = 0x2000
    }

    func matches(_ flags: CGEventFlags) -> Bool {
        flags.intersection([.maskAlternate, .maskCommand, .maskControl, .maskShift]) == flag
            && flags.rawValue & deviceMask != 0
            && flags.rawValue & oppositeDeviceMask == 0
    }

    private var flag: CGEventFlags {
        switch self {
        case .rightOption, .leftOption: .maskAlternate
        case .rightCommand, .leftCommand: .maskCommand
        case .rightControl, .leftControl: .maskControl
        }
    }

    private var deviceMask: UInt64 {
        switch self {
        case .rightOption: DeviceMask.rightOption
        case .leftOption: DeviceMask.leftOption
        case .rightCommand: DeviceMask.rightCommand
        case .leftCommand: DeviceMask.leftCommand
        case .rightControl: DeviceMask.rightControl
        case .leftControl: DeviceMask.leftControl
        }
    }

    private var oppositeDeviceMask: UInt64 {
        switch self {
        case .rightOption: DeviceMask.leftOption
        case .leftOption: DeviceMask.rightOption
        case .rightCommand: DeviceMask.leftCommand
        case .leftCommand: DeviceMask.rightCommand
        case .rightControl: DeviceMask.leftControl
        case .leftControl: DeviceMask.rightControl
        }
    }
}
