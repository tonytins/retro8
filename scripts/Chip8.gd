extends ColorRect

var memory = []
var registers = []
var opcode = 0
var index = 0
var pc = 0
var gfx = []
var delay = 0
var soundTimer = 0
var stack = []
var sp = 0
var keys = []
var isRedraw = true
var canRun =  false
var fontSet = [
	0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
	0x20, 0x60, 0x20, 0x20, 0x70, # 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
	0x90, 0x90, 0xF0, 0x10, 0x10, # 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
	0xF0, 0x10, 0x20, 0x40, 0x40, # 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, # A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
	0xF0, 0x80, 0x80, 0x80, 0xF0, # C
	0xE0, 0x90, 0x90, 0x90, 0xE0, # D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
	0xF0, 0x80, 0xF0, 0x80, 0x80  # F
]


export var displayWidth = 64
export var displayHeight = 32
export var memSize = 4096
export var numRegisters = 16
var displaySize = (displayWidth * displayHeight)
export var stackLevels = 16
export var keyboardBtns = 16

func initSystem():
	
	memory = []
	for i in range(memSize):
		memory.append(0)
	
	registers = []
	for i in range(numRegisters):
		registers.append(0)
	
	gfx = []
	for i in range(displaySize):
		gfx.append(0)
	
	stack = []
	for i in range(stackLevels):
		stack.append(0)
		
	keys = []
	for i in range(keyboardBtns):
		keys.append(0)
	
	opcode = 0
	pc = 0x200
	index = 0
	sp = 0
	isRedraw = true
	
	for i in range(fontSet.size()):
		memory[0x50 + i] = fontSet[i] & 0xFF
	
	
func runSystem():
	var jump = false
	
	opcode = (memory[pc] << 8) | memory[pc + 1]

	var vx = (opcode & 0x0F00) >> 8
	var vy = (opcode & 0x00F0) >> 4
	var vaddr = opcode & 0x0FFF
	var vbyte = (opcode & 0x00FF)
	
	# Instructions
	match (opcode & 0xF000):
		0x0000:
			match (opcode & 0x0FFF):
				0x00E0: # CLS
					for i in range(gfx.size()):
						gfx[i] = 0
					
					isRedraw = true

				0x00EE: # RET
					sp -= 1
					pc = stack[sp] + 2
					jump = true
					
				_:
					pc = vaddr
					jump = true

		0x1000: # JP
			pc = vaddr
			jump = true
			
		0x2000: # CALL
			stack[sp] = pc
			sp += 1
			
			pc = vaddr
			
		0x3000: # SNE Vx, byte
			if (registers[vx] == vbyte):
				pc += 2

		0x4000: # SE Vx, byte
			if (registers[vx] != vbyte):
				pc += 2
				
		0x5000: # SE Vx, Vy
			if (registers[vx] != registers[vy]):
				pc += 2

		0x6000: # LD Vx, byte
			
			registers[vx] = vbyte

		0x7000: # ADD Vx, byte
			registers[vx] = (registers[vx] + vbyte) & 0xFF

		0x8000:
			var result = registers[vx] - registers[vy]

			match (opcode & 0x000F):
				0x0000: # LD Vx, Vy
					registers[vx] = registers[vy]
					
				0x0001: # OR Vx, Vy
					registers[vx] = (registers[vx] | registers[vy]) & 0xFF
				
				0x0002: # AND Vx, Vy
					registers[vx] = (registers[vx] | registers[vy]) & 0xFF
				
				0x0003: # XOR Vx, Vy
					registers[vx] = (registers[vx] ^ registers[vy]) & 0xFF
				
				0x0004: # XOR Vx, Vy

					if (result > 255):
						registers[0xF] = 1
					
					registers[vx] = result & 0xFF

				0x0005: # SUB Vx, Vy
					if (registers[vx] > registers[vy]):
						registers[0xF] = 1
					else:
						registers[0xF] = 0

					registers[vx] = result & 0xFF

				0x0006: # SHR Vx {, Vy}
					var shr_result = registers[vx] & 0x1

					if (shr_result == 1):
						registers[0xF] = 1
					else:
						registers[0xF] = 0
					
					registers[vx] = registers[vx] >> 1

				0x0007: # SUBN Vx, Vy
					if (registers[vy] > registers[vx]):
						registers[0xF] = 1
					else:
						registers[0xF] = 0

					registers[vx] = result & 0xFF

				0x000E: # SHL Vx {, Vy}
					if (result == 1):
						registers[0xF] = 1
					else:
						registers[0xF] = 0
					
					registers[vx] = registers[vx] << 1
				
				_:
					print("Unsupported opcode at 0x8000: %X" ,opcode)
		0x9000: # SNE Vx, Vy
			if (registers[vx] != registers[vy]):
				pc += 2

		0xA000: # LD I, address
			index = vaddr

		0xB000: # JP V0, address
			pc = vaddr + (registers[0x0] & 0xFF)
			jump = true
		
		0xC000: # RND Vx, byte
			var rnd_result = (randi() % 256) & vbyte

			registers[vx] = rnd_result
		
		0xD000: # DRW Vx, Vy, nibble
			var nibble = (opcode & 0x000F)
			var yPos = registers[vx]
			var xPos = registers[vy]

			registers[0xF] = 0

			for yLine in range(nibble):
				var line = memory[index + yLine]

				for xLine in range(8):
					var pixel = line & (0x80 >> xLine)

					if (pixel != 0):
						var totalX = (xPos + xLine) % 64
						var totalY = (yPos + yLine) % 32
						var px_index = (totalY * 64) + totalX

						if (gfx[px_index] == 1):
							registers[0xF] = 1

						gfx[px_index] = gfx[px_index] ^ 1
				
			isRedraw = true
		_:
			print("Unsopported opcode: %X", opcode)
			
	if (jump == false):
		pc += 2
		
	if (delay > 0):
		delay -= 1
	
	if (soundTimer > 0):
		if (soundTimer == 1):
			$AudioStreamPlayer.play()
		
		soundTimer -= 1
		
func loadRom(rom):
	var file = File.new()
	
	if (file.file_exists(rom)):
		initSystem()
		file.open(rom, File.READ)
		
		var offset = 0
		
		while (!file.eof_reached()):
			memory[0x200 + offset] = file.get_8()
			canRun = true
			file.close()
			
			print("Rom loaded.")
	else:
		print("Rom not found")

# Called when the node enters the scene tree for the first time.
func _ready():
	loadRom(SysData.Rom)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
