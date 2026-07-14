
//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Program_Counter
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////

module Program_Counter(
    input wire clk,
    input wire reset,
    input wire enable,

    input wire jumpEnable,
    input wire [7:0] jumpAddress,

    output reg [7:0] pc
);

always @(posedge clk) begin
    if (reset) begin
        pc <= 8'b0000;
    end
    else begin

        if (enable) begin
            
            if (jumpEnable) begin
                pc <= jumpAddress;
            end
            
            else if (pc == 8'd255) begin
                pc <= 8'd0;
            end
            
            else begin
                pc <= pc + 8'd1;
            end
            
        end
    end
end

endmodule