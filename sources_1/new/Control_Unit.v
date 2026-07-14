
//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Control_Unit
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module Control_Unit(

    input wire [15:0] instruction,

    input wire zeroFlag,
    input wire carryFlag,

    output reg [3:0] readSelect1,
    output reg [3:0] readSelect2,
    output reg [3:0] writeSelect,

    output reg registerWriteEnable,

    output reg [3:0] aluOperation,
    output reg flagsWriteEnable,

    output reg [7:0] memoryAddress,
    output reg memoryReadEnable,
    output reg memoryWriteEnable,

    output reg [1:0] writebackSelect,
    output reg [15:0] immediateValue,

    output reg jumpEnable,
    output reg [7:0] jumpAddress
);


    wire instructionToggle = instruction[15];

    wire [3:0] opcode = instruction[14:11];
    wire [3:0] regA   = instruction[10:7];
    wire [3:0] regB   = instruction[6:3];
    wire [2:0] extra  = instruction[2:0];

    wire [6:0] immediate7 = instruction[6:0];

    wire [7:0] branchAddress = instruction[10:3];

    wire [7:0] mmioAddress = {4'hF, regB};


    localparam CLASS_NON_ALU = 1'b0;
    localparam CLASS_ALU     = 1'b1;

    localparam OP_NOP   = 4'h0;
    localparam OP_LDI   = 4'h1;
    localparam OP_LOAD  = 4'h2;
    localparam OP_STORE = 4'h3;
    localparam OP_JMP   = 4'h4;
    localparam OP_JZ    = 4'h5;
    localparam OP_JNZ   = 4'h6;
    localparam OP_JC    = 4'h7;
    localparam OP_JNC   = 4'h8;

    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_NOT_A  = 4'b0101;
    localparam ALU_SHL    = 4'b0110;
    localparam ALU_SHR    = 4'b0111;
    localparam ALU_INC_A  = 4'b1000;
    localparam ALU_DEC_A  = 4'b1001;
    localparam ALU_PASS_A = 4'b1010;
    localparam ALU_PASS_B = 4'b1011;
    localparam ALU_ZERO   = 4'b1100;
    localparam ALU_CMP    = 4'b1101;
    localparam ALU_NAND   = 4'b1110;
    localparam ALU_NOR    = 4'b1111;
    localparam WB_ALU       = 2'b00;
    localparam WB_MEMORY    = 2'b01;
    localparam WB_IMMEDIATE = 2'b10;



    always @(*) begin
    
        readSelect1         = 4'd0;
        readSelect2         = 4'd0;
        writeSelect         = 4'd0;

        registerWriteEnable = 1'b0;

        aluOperation        = ALU_ZERO;
        flagsWriteEnable    = 1'b0;

        memoryAddress       = 8'd0;
        memoryReadEnable    = 1'b0;
        memoryWriteEnable   = 1'b0;

        writebackSelect     = WB_ALU;
        immediateValue      = 16'd0;

        jumpEnable          = 1'b0;
        jumpAddress         = 8'd0;


        if (instructionToggle == CLASS_ALU) begin

            aluOperation     = opcode;

            readSelect1      = regA;
            readSelect2      = regB;
            writeSelect      = regA;

            writebackSelect  = WB_ALU;
            flagsWriteEnable = 1'b1;

            if (opcode == ALU_CMP)
                registerWriteEnable = 1'b0;
            else
                registerWriteEnable = 1'b1;
        end


        else begin

            case (opcode)

                OP_NOP: begin
                    // Do nothing.
                end

                OP_LDI: begin
                    writeSelect         = regA;
                    immediateValue      = {9'd0, immediate7};

                    writebackSelect     = WB_IMMEDIATE;
                    registerWriteEnable = 1'b1;
                end

                OP_LOAD: begin
                    writeSelect         = regA;

                    memoryAddress       = mmioAddress;
                    memoryReadEnable    = 1'b1;

                    writebackSelect     = WB_MEMORY;
                    registerWriteEnable = 1'b1;
                end

                OP_STORE: begin
                    readSelect1       = regA;

                    memoryAddress     = mmioAddress;
                    memoryWriteEnable = 1'b1;
                end

                OP_JMP: begin
                    jumpAddress = branchAddress;
                    jumpEnable  = 1'b1;
                end

                OP_JZ: begin
                    jumpAddress = branchAddress;
                    jumpEnable  = zeroFlag;
                end

                OP_JNZ: begin
                    jumpAddress = branchAddress;
                    jumpEnable  = ~zeroFlag;
                end

                OP_JC: begin
                    jumpAddress = branchAddress;
                    jumpEnable  = carryFlag;
                end

                OP_JNC: begin
                    jumpAddress = branchAddress;
                    jumpEnable  = ~carryFlag;
                end


                default: begin
                    // Unknown non-ALU opcode: do nothing.
                end

            endcase
        end
    end

endmodule
