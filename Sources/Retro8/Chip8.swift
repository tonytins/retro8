import Foundation

public final class Chip8 {
    public static let displayWidth = 64
    public static let displayHeight = 32
    public static let memorySize = 4096
    public static let registerCount = 16
    public static let stackLevels = 16
    public static let keyboardButtons = 16

    public var memory: [UInt8]
    public var registers: [UInt8]
    public var opcode: UInt16 = 0
    public var index: UInt16 = 0
    public var pc: UInt16 = 0x200
    public var gfx: [UInt8]
    public var delayTimer: UInt8 = 0
    public var soundTimer: UInt8 = 0
    public var stack: [UInt16]
    public var sp: Int = 0
    public var keys: [UInt8]
    public var isRedraw = true
    public var canRun = false

    private let fontSet: [UInt8] = [
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80  // F
    ]

    public init() {
        self.memory = Array(repeating: 0, count: Self.memorySize)
        self.registers = Array(repeating: 0, count: Self.registerCount)
        self.gfx = Array(repeating: 0, count: Self.displayWidth * Self.displayHeight)
        self.stack = Array(repeating: 0, count: Self.stackLevels)
        self.keys = Array(repeating: 0, count: Self.keyboardButtons)
        reset()
    }

    public func reset() {
        memory = Array(repeating: 0, count: Self.memorySize)
        registers = Array(repeating: 0, count: Self.registerCount)
        gfx = Array(repeating: 0, count: Self.displayWidth * Self.displayHeight)
        stack = Array(repeating: 0, count: Self.stackLevels)
        keys = Array(repeating: 0, count: Self.keyboardButtons)

        opcode = 0
        pc = 0x200
        index = 0
        sp = 0
        delayTimer = 0
        soundTimer = 0
        isRedraw = true
        canRun = false

        for (offset, value) in fontSet.enumerated() {
            memory[0x50 + offset] = value
        }
    }

    @discardableResult
    public func loadROM(_ data: Data) -> Bool {
        guard !data.isEmpty, data.count <= Self.memorySize - 0x200 else {
            return false
        }

        reset()

        for (offset, byte) in data.enumerated() {
            let memoryIndex = 0x200 + offset
            memory[memoryIndex] = byte
        }

        canRun = true
        return true
    }

    public func setKey(_ keyIndex: Int, pressed: Bool) {
        guard keyIndex >= 0, keyIndex < keys.count else {
            return
        }
        keys[keyIndex] = pressed ? 1 : 0
    }

    public func cycle() {
        guard canRun else {
            return
        }

        let pcIndex = Int(pc)
        guard pcIndex + 1 < memory.count else {
            return
        }

        opcode = UInt16(memory[pcIndex]) << 8 | UInt16(memory[pcIndex + 1])

        let x = Int((opcode & 0x0F00) >> 8)
        let y = Int((opcode & 0x00F0) >> 4)
        let address = opcode & 0x0FFF
        let byte = UInt8(opcode & 0x00FF)
        let nibble = opcode & 0x000F

        var jump = false

        switch opcode & 0xF000 {
        case 0x0000:
            switch opcode & 0x0FFF {
            case 0x00E0:
                gfx = Array(repeating: 0, count: Self.displayWidth * Self.displayHeight)
                isRedraw = true
            case 0x00EE:
                guard sp > 0 else {
                    return
                }
                sp -= 1
                pc = stack[sp] + 2
                jump = true
            default:
                pc = address
                jump = true
            }

        case 0x1000:
            pc = address
            jump = true

        case 0x2000:
            guard sp < stack.count else {
                return
            }
            stack[sp] = pc
            sp += 1
            pc = address
            jump = true

        case 0x3000:
            if registers[x] == byte {
                pc += 2
            }

        case 0x4000:
            if registers[x] != byte {
                pc += 2
            }

        case 0x5000:
            if registers[x] == registers[y] {
                pc += 2
            }

        case 0x6000:
            registers[x] = byte

        case 0x7000:
            registers[x] = (registers[x] &+ byte) & 0xFF

        case 0x8000:
            switch nibble {
            case 0x0000:
                registers[x] = registers[y]
            case 0x0001:
                registers[x] = registers[x] | registers[y]
            case 0x0002:
                registers[x] = registers[x] & registers[y]
            case 0x0003:
                registers[x] = registers[x] ^ registers[y]
            case 0x0004:
                let result = UInt16(registers[x]) + UInt16(registers[y])
                registers[0xF] = result > 0xFF ? 1 : 0
                registers[x] = UInt8(result & 0xFF)
            case 0x0005:
                registers[0xF] = registers[x] >= registers[y] ? 1 : 0
                registers[x] = registers[x] &- registers[y]
            case 0x0006:
                registers[0xF] = registers[x] & 0x01
                registers[x] >>= 1
            case 0x0007:
                registers[0xF] = registers[y] >= registers[x] ? 1 : 0
                registers[x] = registers[y] &- registers[x]
            case 0x000E:
                registers[0xF] = (registers[x] & 0x80) >> 7
                registers[x] <<= 1
            default:
                print("Unsupported opcode at 0x8000: \(String(opcode, radix: 16, uppercase: true))")
            }

        case 0x9000:
            if registers[x] != registers[y] {
                pc += 2
            }

        case 0xA000:
            index = address

        case 0xB000:
            pc = address + UInt16(registers[0])
            jump = true

        case 0xC000:
            let randomByte = UInt8.random(in: 0...255)
            registers[x] = randomByte & byte

        case 0xD000:
            let totalRows = Int(nibble)
            let spriteX = Int(registers[x])
            let spriteY = Int(registers[y])
            registers[0xF] = 0

            for row in 0..<totalRows {
                let spriteRow = memory[Int(index) + row]

                for column in 0..<8 {
                    let pixelMask = UInt8(0x80 >> column)
                    let activePixel = (spriteRow & pixelMask) != 0

                    if activePixel {
                        let displayX = (spriteX + column) % Self.displayWidth
                        let displayY = (spriteY + row) % Self.displayHeight
                        let displayIndex = displayY * Self.displayWidth + displayX

                        if gfx[displayIndex] == 1 {
                            registers[0xF] = 1
                        }

                        gfx[displayIndex] ^= 1
                    }
                }
            }

            isRedraw = true

        case 0xE000:
            switch opcode & 0x00FF {
            case 0x009E:
                if keys[Int(registers[x])] != 0 {
                    pc += 2
                }
            case 0x00A1:
                if keys[Int(registers[x])] == 0 {
                    pc += 2
                }
            default:
                print("Unsupported opcode at 0xE000: \(String(opcode, radix: 16, uppercase: true))")
            }

        case 0xF000:
            switch opcode & 0x00FF {
            case 0x0007:
                registers[x] = delayTimer
            case 0x000A:
                var keyPressed = false
                for (keyIndex, keyState) in keys.enumerated() where keyState != 0 {
                    registers[x] = UInt8(keyIndex)
                    keyPressed = true
                    break
                }

                if !keyPressed {
                    return
                }
            case 0x0015:
                delayTimer = registers[x]
            case 0x0018:
                soundTimer = registers[x]
            case 0x001E:
                index = index &+ UInt16(registers[x])
            case 0x0029:
                index = UInt16(0x50 + (Int(registers[x]) * 5))
            case 0x0033:
                let value = registers[x]
                memory[Int(index)] = value / 100
                memory[Int(index) + 1] = (value / 10) % 10
                memory[Int(index) + 2] = value % 10
            case 0x0055:
                for offset in 0...x {
                    memory[Int(index) + offset] = registers[offset]
                }
            case 0x0065:
                for offset in 0...x {
                    registers[offset] = memory[Int(index) + offset]
                }
            default:
                print("Unsupported opcode at 0xF000: \(String(opcode, radix: 16, uppercase: true))")
            }

        default:
            print("Unsupported opcode: \(String(opcode, radix: 16, uppercase: true))")
        }

        if !jump {
            pc += 2
        }

        if delayTimer > 0 {
            delayTimer -= 1
        }

        if soundTimer > 0 {
            soundTimer -= 1
        }
    }
}
