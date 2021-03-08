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
					var address = opcode & 0x0FFF
					pc = address
					jump = true
		0x1000: # JP
			var address = opcode & 0x0FFF
			pc = address
			jump = true
			
		0x2000: # CALL
			var address = opcode & 0x0FFF
			stack[sp] = pc
			sp += 1
			
			pc = address
			
		0x3000: # SNE Vx, byte
			var vx = (opcode & 0x0F00) > 8
			var byte = (opcode & 0x00FF)
			
			if (registers[vx] != byte):
				pc += 2
				
			if (registers[vx] != byte):
				pc += 2
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
