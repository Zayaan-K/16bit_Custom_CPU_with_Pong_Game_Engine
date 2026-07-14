
//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Keyboard_Handler
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module Keyboard_Handler(

    input  wire clk,
    input  wire reset,

    input  wire ps2Clk,
    input  wire ps2Data,

    output reg        done,
    output reg        error,
    output reg [7:0]  scanCode
);

    localparam IDLE    = 1'b0;
    localparam RECEIVE = 1'b1;

    reg state = IDLE;

    reg [3:0]  bitCount = 4'd0;
    reg [10:0] frame    = 11'd0;


    reg [2:0] ps2ClkSync  = 3'b111;
    reg [2:0] ps2DataSync = 3'b111;

    always @(posedge clk) begin
        ps2ClkSync  <= {ps2ClkSync[1:0], ps2Clk};
        ps2DataSync <= {ps2DataSync[1:0], ps2Data};
    end

    wire ps2ClkFalling;
    wire sampledData;

    assign ps2ClkFalling = (ps2ClkSync[2:1] == 2'b10);
    assign sampledData   = ps2DataSync[2];

    wire       startBit;
    wire [7:0] receivedData;
    wire       parityBit;
    wire       stopBit;
    wire       parityOk;
    wire       frameOk;

    assign startBit     = frame[0];
    assign receivedData = frame[8:1];
    assign parityBit    = frame[9];
    assign stopBit      = sampledData;

    assign parityOk = ((^receivedData) ^ parityBit) == 1'b1;

    assign frameOk = (startBit == 1'b0) &&
                     (stopBit  == 1'b1) &&
                     parityOk;

    always @(posedge clk) begin
        if (reset) begin
            state    <= IDLE;
            bitCount <= 4'd0;
            frame    <= 11'd0;
            scanCode <= 8'd0;
            done     <= 1'b0;
            error    <= 1'b0;
        end else begin
            done  <= 1'b0;
            error <= 1'b0;

            case (state)

                IDLE: begin
                    bitCount <= 4'd0;

                    if (ps2ClkFalling && sampledData == 1'b0) begin
                        frame[0] <= sampledData;
                        bitCount <= 4'd1;
                        state    <= RECEIVE;
                    end
                end

                RECEIVE: begin
                    if (ps2ClkFalling) begin

                        if (bitCount < 4'd10) begin
                            frame[bitCount] <= sampledData;
                            bitCount <= bitCount + 1'b1;
                        end

                        else begin

                            bitCount <= 4'd0;
                            state    <= IDLE;

                            if (frameOk) begin
                                scanCode <= receivedData;
                                done     <= 1'b1;
                            end else begin
                                error <= 1'b1;
                            end
                        end

                    end
                end

                default: begin
                    state    <= IDLE;
                    bitCount <= 4'd0;
                    done     <= 1'b0;
                    error    <= 1'b0;
                end

            endcase
        end
    end


endmodule
