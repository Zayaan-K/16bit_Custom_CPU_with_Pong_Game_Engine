//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: CPU_top
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: CPU core wrapper
// 
//////////////////////////////////////////////////////////////////////////////////

module CPU_top(
    input  wire clk,
    input  wire reset,
    input  wire cpuEnable,

    input  wire [15:0] memoryReadData,
    output wire [7:0]  memoryAddress,
    output wire [15:0] memoryWriteData,
    output wire        memoryWriteEnable,


    output wire [7:0]  debugPC,
    output wire [15:0] debugInstruction,
    output wire [15:0] debugALUResult,
    output wire [15:0] debugRegA,
    output wire [15:0] debugRegB,
    output wire        debugZeroFlag,
    output wire        debugCarryFlag
);


    wire [7:0]  pc;
    wire [15:0] instruction;

    wire [3:0] readSelect1;
    wire [3:0] readSelect2;
    wire [3:0] writeSelect;

    wire registerWriteEnableRaw;

    wire [3:0] aluOperation;
    wire       flagsWriteEnable;

    wire [7:0] controlMemoryAddress;
    wire       memoryReadEnable;
    wire       memoryWriteEnableRaw;

    wire [1:0]  writebackSelect;
    wire [15:0] immediateValue;

    wire       jumpEnable;
    wire [7:0] jumpAddress;

    wire [15:0] readData1;
    wire [15:0] readData2;

    wire [15:0] aluResult;
    wire        aluZeroFlag;
    wire        aluCarryFlag;

    reg zeroFlagReg;
    reg carryFlagReg;

    reg [15:0] registerWriteData;


    localparam WB_ALU       = 2'b00;
    localparam WB_MEMORY    = 2'b01;
    localparam WB_IMMEDIATE = 2'b10;




    Program_Counter pc_inst(
        .clk(clk),
        .reset(reset),
        .enable(cpuEnable),

        .jumpEnable(jumpEnable),
        .jumpAddress(jumpAddress),

        .pc(pc)
    );




    Instruction_Memory instruction_memory_inst(
        .address(pc),
        .instruction(instruction)
    );



    Control_Unit control_unit_inst(
        .instruction(instruction),

        .zeroFlag(zeroFlagReg),
        .carryFlag(carryFlagReg),

        .readSelect1(readSelect1),
        .readSelect2(readSelect2),
        .writeSelect(writeSelect),

        .registerWriteEnable(registerWriteEnableRaw),

        .aluOperation(aluOperation),
        .flagsWriteEnable(flagsWriteEnable),

        .memoryAddress(controlMemoryAddress),
        .memoryReadEnable(memoryReadEnable),
        .memoryWriteEnable(memoryWriteEnableRaw),

        .writebackSelect(writebackSelect),
        .immediateValue(immediateValue),

        .jumpEnable(jumpEnable),
        .jumpAddress(jumpAddress)
    );


Register_File register_file_inst(
    .clk(clk),
    .reset(reset),
    .writeEnable(cpuEnable && registerWriteEnableRaw),

    .Select1(readSelect1),
    .Select2(readSelect2),
    .writeSelect(writeSelect),

    .writeData(registerWriteData),

    .readData1(readData1),
    .readData2(readData2)
);

    ALU alu_inst(
        .zeroFlag(aluZeroFlag),
        .carryFlag(aluCarryFlag),

        .A(readData1),
        .B(readData2),

        .computed(aluResult),

        .operation(aluOperation)
    );


    always @(posedge clk) begin
        if (reset) begin
            zeroFlagReg  <= 1'b0;
            carryFlagReg <= 1'b0;
        end
        else if (cpuEnable && flagsWriteEnable) begin
            zeroFlagReg  <= aluZeroFlag;
            carryFlagReg <= aluCarryFlag;
        end
    end


    always @(*) begin
        case (writebackSelect)

            WB_ALU: begin
                registerWriteData = aluResult;
            end

            WB_MEMORY: begin
                registerWriteData = memoryReadData;
            end

            WB_IMMEDIATE: begin
                registerWriteData = immediateValue;
            end

            default: begin
                registerWriteData = 16'd0;
            end

        endcase
    end

    assign memoryAddress     = controlMemoryAddress;
    assign memoryWriteData   = readData1;
    assign memoryWriteEnable = cpuEnable && memoryWriteEnableRaw;

    assign debugPC          = pc;
    assign debugInstruction = instruction;
    assign debugALUResult   = aluResult;
    assign debugRegA        = readData1;
    assign debugRegB        = readData2;
    assign debugZeroFlag    = zeroFlagReg;
    assign debugCarryFlag   = carryFlagReg;

endmodule