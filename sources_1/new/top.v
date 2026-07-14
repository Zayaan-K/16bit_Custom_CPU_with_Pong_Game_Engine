//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: top
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: Basys 3 top-level wrapper
// 
//////////////////////////////////////////////////////////////////////////////////

module top(
    input  wire clk,
    input  wire reset,

    input  wire PS2Clk,
    input  wire PS2Data,

    output wire Hsync,
    output wire Vsync,

    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,

    output wire [15:0] led
);

    //============================================================
    // VGA wires
    //============================================================

    wire [9:0] xCoordinate;
    wire [9:0] yCoordinate;
    wire       activeVideo;
    wire       frameTick;
    wire       pixelTick;


    //============================================================
    // Keyboard wires
    //============================================================

    wire       scanDone;
    wire       scanError;
    wire [7:0] scanCode;
    wire [3:0] keyState;


    //============================================================
    // CPU/MMIO wires
    //============================================================

    wire [7:0]  cpuMemoryAddress;
    wire [15:0] cpuMemoryWriteData;
    wire        cpuMemoryWriteEnable;
    wire [15:0] cpuMemoryReadData;

    wire [15:0] unusedReadData2;


    //============================================================
    // Game register wires
    //============================================================

    wire [15:0] ball_X;
    wire [15:0] ball_Y;
    wire [15:0] ball_X_Direction;
    wire [15:0] ball_Y_Direction;
    wire [15:0] ball_Speed;

    wire [15:0] player_Y;
    wire [15:0] player_Score;

    wire [15:0] AI_Y;
    wire [15:0] AI_Score;

    wire [15:0] game_Paused;
    wire [15:0] game_Reset;
    wire [15:0] game_Over;
    wire [15:0] Frame_Ready;


    //============================================================
    // CPU debug wires
    //============================================================

    wire [7:0]  debugPC;
    wire [15:0] debugInstruction;
    wire [15:0] debugALUResult;
    wire [15:0] debugRegA;
    wire [15:0] debugRegB;
    wire        debugZeroFlag;
    wire        debugCarryFlag;


    //============================================================
    // Sticky keyboard debug
    //
    // scanDone is only one clock cycle long, so it is too fast
    // to see directly on an LED. These registers latch the event.
    //============================================================

    reg stickyScanDone  = 1'b0;
    reg stickyScanError = 1'b0;

    always @(posedge clk) begin
        if (reset) begin
            stickyScanDone  <= 1'b0;
            stickyScanError <= 1'b0;
        end
        else begin
            if (scanDone)
                stickyScanDone <= 1'b1;

            if (scanError)
                stickyScanError <= 1'b1;
        end
    end


    //============================================================
    // VGA Driver
    //============================================================

    VGA_Driver vga_driver_inst(
        .clk(clk),
        .reset(reset),

        .Hsync(Hsync),
        .Vsync(Vsync),

        .xCoordinate(xCoordinate),
        .yCoordinate(yCoordinate),

        .activeVideo(activeVideo),
        .frameTick(frameTick),
        .pixelTick(pixelTick)
    );


    //============================================================
    // Raw PS/2 receiver
    //============================================================

    Keyboard_Handler keyboard_handler_inst(
        .clk(clk),
        .reset(reset),

        .ps2Clk(PS2Clk),
        .ps2Data(PS2Data),

        .done(scanDone),
        .error(scanError),
        .scanCode(scanCode)
    );


    //============================================================
    // Scan-code to key-state converter
    //
    // keyState[0] = W / up held
    // keyState[1] = S / down held
    // keyState[2] = R / reset held
    // keyState[3] = P / pause held
    //============================================================

    Pressed_Key_State_Updater key_state_inst(
        .clk(clk),
        .reset(reset),

        .done(scanDone),
        .error(scanError),
        .scanCode(scanCode),

        .keyState(keyState)
    );


    //============================================================
    // CPU core
    //============================================================

    CPU_top cpu_inst(
        .clk(clk),
        .reset(reset),
        .cpuEnable(1'b1),

        .memoryReadData(cpuMemoryReadData),
        .memoryAddress(cpuMemoryAddress),
        .memoryWriteData(cpuMemoryWriteData),
        .memoryWriteEnable(cpuMemoryWriteEnable),

        .debugPC(debugPC),
        .debugInstruction(debugInstruction),
        .debugALUResult(debugALUResult),
        .debugRegA(debugRegA),
        .debugRegB(debugRegB),
        .debugZeroFlag(debugZeroFlag),
        .debugCarryFlag(debugCarryFlag)
    );


    //============================================================
    // Memory-mapped registers
    //============================================================

    Memory_Mapped_Registers mmio_inst(
        .clk(clk),
        .reset(reset),

        .frameTick(frameTick),
        .writeEnable(cpuMemoryWriteEnable),

        .readAddress1(cpuMemoryAddress),
        .readAddress2(8'd0),
        .writeAddress(cpuMemoryAddress),

        .writeData(cpuMemoryWriteData),

        .keyState(keyState),

        .readData1(cpuMemoryReadData),
        .readData2(unusedReadData2),

        .ball_X(ball_X),
        .ball_Y(ball_Y),
        .ball_X_Direction(ball_X_Direction),
        .ball_Y_Direction(ball_Y_Direction),
        .ball_Speed(ball_Speed),

        .player_Y(player_Y),
        .player_Score(player_Score),

        .AI_Y(AI_Y),
        .AI_Score(AI_Score),

        .game_Paused(game_Paused),
        .game_Reset(game_Reset),
        .game_Over(game_Over),
        .Frame_Ready(Frame_Ready)
    );


    //============================================================
    // Renderer
    //============================================================

    Renderer renderer_inst(
        .xCoordinate(xCoordinate),
        .yCoordinate(yCoordinate),
        .activeVideo(activeVideo),

        .ball_X(ball_X),
        .ball_Y(ball_Y),
        .player_Y(player_Y),
        .AI_Y(AI_Y),

        .player_Score(player_Score),
        .AI_Score(AI_Score),

        .game_Paused(game_Paused),
        .game_Over(game_Over),

        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );


    //============================================================
    // Debug LEDs
    //
    // led[7:0]   = latest PS/2 scan code
    // led[11:8]  = keyState
    //              led[8]  = up
    //              led[9]  = down
    //              led[10] = reset
    //              led[11] = pause
    //
    // led[12]    = sticky scanDone seen
    // led[13]    = sticky scanError seen
    // led[15:14] = low PC bits, proves CPU is running
    //============================================================

    assign led[7:0]   = scanCode;
    assign led[11:8]  = keyState;
    assign led[12]    = stickyScanDone;
    assign led[13]    = stickyScanError;
    assign led[15:14] = debugPC[1:0];

endmodule