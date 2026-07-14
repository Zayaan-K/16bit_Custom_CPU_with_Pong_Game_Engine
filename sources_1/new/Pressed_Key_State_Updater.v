//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Key_State_Updater
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////

module Pressed_Key_State_Updater(

    input  wire       clk,
    input  wire       reset,

    input  wire       done,
    input  wire       error,
    input  wire [7:0] scanCode,

    output reg [3:0]  keyState
);

    // keyState[0] = W / up held
    // keyState[1] = S / down held
    // keyState[2] = R / reset key held
    // keyState[3] = P / pause key held

    localparam SCAN_W     = 8'h1D;
    localparam SCAN_S     = 8'h1B;
    localparam SCAN_R     = 8'h2D;
    localparam SCAN_P     = 8'h4D;
    localparam BREAK_CODE = 8'hF0;

    reg breakCodeSeen = 1'b0;

    always @(posedge clk) begin
        if (reset) begin
            keyState      <= 4'b0000;
            breakCodeSeen <= 1'b0;
        end else begin

            if (error) begin
                breakCodeSeen <= 1'b0;
            end

            else if (done) begin

                if (scanCode == BREAK_CODE) begin
                    breakCodeSeen <= 1'b1;
                end

                else begin
                    case (scanCode)

                        SCAN_W: begin
                            keyState[0] <= ~breakCodeSeen;
                        end

                        SCAN_S: begin
                            keyState[1] <= ~breakCodeSeen;
                        end

                        SCAN_R: begin
                            keyState[2] <= ~breakCodeSeen;
                        end

                        SCAN_P: begin
                            keyState[3] <= ~breakCodeSeen;
                        end

                        default: begin
                        end

                    endcase

                    breakCodeSeen <= 1'b0;
                end
            end
        end
    end

endmodule

