# 16-Bit Custom CPU with Pong Game Engine

A custom 16-bit processor and hardware-accelerated Pong game implemented in Verilog for the Digilent Basys 3 FPGA. The project combines a programmable CPU, a custom instruction set, memory-mapped game state, VGA graphics, and PS/2 keyboard input in a complete FPGA system.

The Pong game logic is executed as a program stored in instruction memory. The CPU updates the ball, paddles, collisions, and scores through memory-mapped registers, while dedicated hardware generates the VGA display and processes keyboard input.

## Features

- Custom 16-bit processor written in Verilog
- Custom RISC-style instruction set architecture (ISA)
- 16-bit arithmetic logic unit with arithmetic, logical, shift, and comparison operations
- General-purpose register file
- Program counter, instruction memory, decoder, and control unit
- Memory-mapped I/O interface for communication between the CPU and game hardware
- Pong game programmed using the custom instruction set
- Ball movement and increasing rally speed
- Player and computer-controlled paddles
- Paddle and screen-boundary collision detection
- Player and AI scoring
- VGA output at 640 × 480 and approximately 60 Hz
- Hardware-rendered paddles, ball, and seven-segment-style scores
- PS/2 keyboard controls using Scan Code Set 2
- Clock-domain crossing protection for asynchronous external input
- Synthesizable for the Digilent Basys 3 (Xilinx Artix-7) FPGA

## System Architecture

```text
                       +----------------------+
                       |  Instruction Memory  |
                       +----------+-----------+
                                  |
                                  v
+-----------+    +----------------+----------------+
| Program   |--->|        16-Bit CPU Core          |
| Counter   |    | Control Unit | Registers | ALU  |
+-----------+    +----------------+----------------+
                                  |
                                  | Memory-mapped I/O
                                  v
                    +-------------+-------------+
                    |       Game Registers      |
                    | Ball | Paddles | Scores   |
                    | Speed | Pause | Game State|
                    +------+------+-------------+
                           |      |
                 +---------+      +----------+
                 v                           v
        +----------------+          +----------------+
        |  VGA Renderer  |          | Keyboard State |
        | 640 × 480 RGB  |          |  PS/2 Receiver |
        +-------+--------+          +-------+--------+
                |                           |
                v                           v
           VGA monitor                 PS/2 keyboard
```

## CPU Architecture

### Datapath

The CPU uses a 16-bit datapath. Its main components are:

- **Program counter:** Selects the next instruction and supports sequential execution, jumps, and branches.
- **Instruction memory:** Stores the machine-code program that implements the Pong game logic.
- **Control unit:** Decodes each instruction and generates the required datapath, register, ALU, and memory control signals.
- **Register file:** Provides general-purpose registers for operands, intermediate values, coordinates, and game calculations.
- **ALU:** Executes arithmetic, bitwise, shift, pass-through, and comparison operations.
- **Memory interface:** Connects load and store instructions to the memory-mapped game registers.

### ALU Operations

The ALU supports the following operation categories:

| Category | Operations |
| --- | --- |
| Arithmetic | Add, subtract, increment, decrement |
| Logical | AND, OR, XOR, NAND, NOR, NOT |
| Shift | Logical shift left and right |
| Data movement | Pass operand A, pass operand B, output zero |
| Comparison | Compare values and update status flags |

The CPU exposes zero and carry/borrow status information for conditional control flow.

### Custom Instruction Set

The processor uses a compact, RISC-style instruction format. Instruction classes include:

- Register-to-register ALU operations
- Immediate-value operations
- Loads from memory-mapped registers
- Stores to memory-mapped registers
- Unconditional jumps
- Conditional branches

The exact opcode and bit-field definitions should be documented in `docs/ISA.md` as the architecture evolves. The program in instruction memory serves as the current reference implementation.

## Memory-Mapped I/O

The game engine exposes its state to the CPU as memory-mapped registers. This allows normal load and store instructions to read inputs and update the display state.

| Address | Register | Purpose |
| --- | --- | --- |
| `0xF0` | Ball X | Horizontal ball coordinate |
| `0xF1` | Ball Y | Vertical ball coordinate |
| `0xF2` | Ball X direction | Horizontal direction of travel |
| `0xF3` | Ball Y direction | Vertical direction of travel |
| `0xF4` | Ball speed | Current movement speed |
| `0xF5` | Player Y | Player paddle position |
| `0xF6` | Player score | Player score value |
| `0xF7` | AI Y | Computer paddle position |
| `0xF8` | AI score | Computer score value |
| `0xF9` | Pause state | Indicates whether gameplay is paused |
| `0xFA` | Reset state | Requests or reports a game reset |
| `0xFB` | Game-over state | Indicates the end-of-game condition |

These registers form the interface between the programmable CPU and the dedicated graphics hardware.

## Pong Game Engine

The Pong program is stored as custom machine instructions in instruction memory. During gameplay, the CPU:

1. Waits for or responds to a new video frame.
2. Reads the current keyboard and game state.
3. Updates the player's paddle position.
4. Moves the AI paddle toward the ball.
5. Updates the ball position using its direction and speed.
6. Detects top and bottom boundary collisions.
7. Detects paddle collisions and reverses the ball direction.
8. Updates the score when the ball passes a paddle.
9. Resets the ball position and speed after a point.
10. Writes the updated state to the memory-mapped registers.

Using instructions for gameplay rather than hard-wiring all game behavior demonstrates how software can control custom hardware through a defined architecture.

## VGA Graphics

The VGA subsystem produces a 640 × 480 display at approximately 60 Hz. It generates:

- Horizontal and vertical synchronization signals
- Current pixel coordinates
- An active-video indicator
- A frame-timing pulse used to coordinate gameplay updates
- 4-bit red, green, and blue color channels

The renderer compares the current pixel coordinate against the positions stored in the game registers. It draws the ball, paddles, play area, and seven-segment-style scores in real time without using a framebuffer.

## PS/2 Keyboard Interface

The keyboard receiver captures PS/2 Scan Code Set 2 frames and converts make and break codes into persistent key states.

| Key | Function |
| --- | --- |
| `W` | Move player paddle up |
| `S` | Move player paddle down |
| `P` | Pause or resume the game |
| `R` | Reset the game |

The external PS/2 clock is asynchronous relative to the FPGA's 100 MHz system clock. Synchronizer registers and edge detection are used before the signal enters the internal control logic, reducing the risk of metastability and enabling safe clock-domain crossing.

## Hardware Requirements

- Digilent Basys 3 FPGA development board
- PS/2-compatible keyboard
- VGA monitor or a compatible VGA display adapter
- VGA cable
- Micro-USB cable for power and FPGA programming
- Computer with AMD/Xilinx Vivado installed

## Building and Programming

1. Clone the repository:

   ```bash
   git clone https://github.com/Zayaan-K/16bit_Custom_CPU_With_Pong_Game_Engine.git
   cd 16bit_Custom_CPU_With_Pong_Game_Engine
   ```

2. Open Vivado and create or open the project.
3. Add the Verilog files as design sources.
4. Add the testbenches as simulation sources.
5. Add the Basys 3 `.xdc` file as a constraints source.
6. Select the top-level system module.
7. Run synthesis, implementation, and bitstream generation.
8. Connect the Basys 3 and open **Hardware Manager**.
9. Program the FPGA with the generated `.bit` file.
10. Connect the VGA monitor and PS/2 keyboard, then reset the design.

> The exact Vivado top-module name and source paths depend on the repository layout. Update this section once the final folder structure is committed.

## Suggested Repository Structure

```text
16bit_Custom_CPU_With_Pong_Game_Engine/
├── README.md
├── LICENSE
├── .gitignore
├── constraints/
│   └── Basys3.xdc
├── src/
│   ├── cpu/
│   │   ├── ALU.v
│   │   ├── Control_Unit.v
│   │   ├── Program_Counter.v
│   │   ├── Register_File.v
│   │   └── Instruction_Memory.v
│   ├── game/
│   │   ├── Memory_Mapped_Registers.v
│   │   └── Renderer.v
│   ├── input/
│   │   ├── Keyboard_Handler.v
│   │   └── Key_State_Updater.v
│   ├── video/
│   │   └── VGA_Driver.v
│   └── top/
│       └── Top.v
├── sim/
│   └── testbenches/
├── docs/
│   ├── ISA.md
│   ├── architecture.md
│   └── images/
└── release/
    └── system.bit
```

Rename the example files above to match the actual module filenames in the project.

## Simulation and Verification

Individual modules can be verified with focused testbenches before testing the complete system. Recommended tests include:

- ALU operation and flag verification
- Program counter increment, jump, branch, reset, and wraparound
- Register reads and writes
- Instruction decoding and control-signal generation
- Memory-mapped register access
- PS/2 make-code, break-code, parity, and error handling
- VGA synchronization timing and pixel-coordinate generation
- Paddle, wall, scoring, and ball-reset behavior
- Full CPU instruction traces for short game-program sequences

## Design Highlights

- Integrates processor design, digital logic, graphics, and external communication protocols in one system.
- Separates programmable game behavior from dedicated rendering hardware.
- Uses memory-mapped I/O to create a clean hardware/software interface.
- Handles an asynchronous peripheral safely through synchronization and edge detection.
- Demonstrates a complete path from instruction fetch to a visible, interactive result.

## Current Limitations

- The Pong program is stored directly in instruction memory rather than loaded at runtime.
- The custom ISA does not currently have a complete assembler or compiler toolchain.
- Graphics are produced by fixed-function rendering logic rather than a framebuffer or general-purpose graphics processor.
- Input is limited to supported PS/2 keyboards and the implemented scan codes.
- The design targets the Basys 3 and its available FPGA, clock, VGA, and PS/2 resources.

## Future Improvements

- Create an assembler for the custom ISA
- Store programs in a `.mem` or `.hex` file
- Expand instruction and data memory
- Add a stack, subroutine calls, and interrupts
- Add more status flags and branch conditions
- Add debugging output through UART
- Add automated self-checking testbenches
- Improve the AI and add difficulty settings
- Add sound effects through PWM audio
- Add sprites, a framebuffer, or a more capable rendering engine
- Add a bootloader or external program storage

## What I Learned

This project provided practical experience with:

- CPU datapath and control-unit design
- Instruction-set and machine-code design
- Register files, ALUs, program counters, and instruction memories
- Memory-mapped I/O
- FPGA synthesis, implementation, timing, and debugging
- VGA timing and real-time raster graphics
- PS/2 serial communication
- Clock-domain crossing and metastability mitigation
- Integrating independently developed hardware modules into a complete system

## License

Add a license file before publishing or accepting contributions. The MIT License is a common option for open-source hardware-description projects, but choose the license that matches how you want others to use your work.

## Author

**Zayaan Khandakar**  
GitHub: [Zayaan-K](https://github.com/Zayaan-K)
