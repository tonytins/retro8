import Foundation
import ArgumentParser
import Raylib

@main
struct Retro8: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "retro8",
        abstract: "Run a CHIP-8 ROM."
    )

    @Option(name: .long, help: ArgumentHelp("Path to the CHIP-8 ROM to run.", valueName: "file"))
    var load: String

    mutating func run() throws {
        let chip8 = Chip8()
        let romData: Data

        do {
            romData = try Data(contentsOf: URL(fileURLWithPath: load))
        } catch {
            throw ValidationError("Unable to read ROM '\(load)': \(error.localizedDescription)")
        }

        guard chip8.loadROM(romData) else {
            throw ValidationError("ROM '\(load)' must contain between 1 and \(Chip8.memorySize - 0x200) bytes.")
        }

        runEmulator(chip8)
    }
}

private func runEmulator(_ chip8: Chip8) {
    let scale = 8
    InitWindow(Int32(Chip8.displayWidth * scale), Int32(Chip8.displayHeight * scale), "Retro-8")
    SetTargetFPS(60)

    while !WindowShouldClose() {
        chip8.cycle()

        BeginDrawing()
        ClearBackground(.black)

        for y in 0..<Chip8.displayHeight {
            for x in 0..<Chip8.displayWidth {
                let pixelIndex = y * Chip8.displayWidth + x
                if chip8.gfx[pixelIndex] == 1 {
                    DrawRectangle(
                        Int32(x * scale),
                        Int32(y * scale),
                        Int32(scale),
                        Int32(scale),
                        .white
                    )
                }
            }
        }

        EndDrawing()
    }

    CloseWindow()
}