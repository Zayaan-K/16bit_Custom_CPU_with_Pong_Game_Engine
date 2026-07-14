//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Register_File
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////

module Register_File(
    input wire clk,
    input wire reset,
    input wire writeEnable,

    input wire [3:0] Select1,
    input wire [3:0] Select2,
    input wire [3:0] writeSelect,

    input wire [15:0] writeData,

    output wire [15:0] readData1,
    output wire [15:0] readData2
);

    reg [15:0] registers [0:15];

    integer i;

    assign readData1 = registers[Select1];
    assign readData2 = registers[Select2];

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 16'd0;
            end
        end
        else if (writeEnable) begin
            registers[writeSelect] <= writeData;
        end
    end

endmodule