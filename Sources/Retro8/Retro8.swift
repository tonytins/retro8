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
    let windowWidth = Chip8.displayWidth * scale
    let windowHeight = Chip8.displayHeight * scale
    InitWindow(Int32(windowWidth), Int32(windowHeight), "Retro-8")
    SetTargetFPS(60)

    let resourcePath = Bundle.module.resourcePath ?? ""
    let logoPath = "\(resourcePath)/logo.png"
    let logoImage = LoadImage(logoPath)
    let logoTexture = LoadTextureFromImage(logoImage)
    UnloadImage(logoImage)

    let logoWidth = Int(logoTexture.width)
    let logoHeight = Int(logoTexture.height)
    let logoX = (windowWidth - logoWidth) / 2
    let logoY = (windowHeight - logoHeight) / 2
    let fadeDuration = 8.0

    while !WindowShouldClose() {
        let isShowingLogo = GetTime() < fadeDuration

        if !isShowingLogo {
            chip8.cycle()
        }

        BeginDrawing()
        ClearBackground(.black)

        if isShowingLogo {
            let fade = (1.0 - cos(GetTime() * 2.0 * .pi / fadeDuration)) / 2.0
            let alpha = UInt8(fade * 255.0)
            let logoColor = Color(r: 255, g: 255, b: 255, a: alpha)

            DrawTexture(logoTexture, logoX, logoY, logoColor)
        } else {
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
        }

        EndDrawing()
    }

    UnloadTexture(logoTexture)

    CloseWindow()
}