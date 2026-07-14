//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Memory_Mapped_Registers
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: Memory-mapped game registers for CPU-controlled Pong
// 
//////////////////////////////////////////////////////////////////////////////////

module Memory_Mapped_Registers(
    input wire clk,
    input wire reset,

    input wire frameTick,     
    input wire writeEnable,

    input wire [7:0] readAddress1,
    input wire [7:0] readAddress2,
    input wire [7:0] writeAddress,

    input wire [15:0] writeData,

    input wire [3:0] keyState,

    output reg [15:0] readData1,
    output reg [15:0] readData2,

    output reg [15:0] ball_X,
    output reg [15:0] ball_Y,
    output reg [15:0] ball_X_Direction,
    output reg [15:0] ball_Y_Direction,
    output reg [15:0] ball_Speed,

    output reg [15:0] player_Y,
    output reg [15:0] player_Score,

    output reg [15:0] AI_Y,
    output reg [15:0] AI_Score,

    output reg [15:0] game_Paused,
    output reg [15:0] game_Reset,
    output reg [15:0] game_Over,

    output reg [15:0] Frame_Ready
);

    localparam ADDR_BALL_X           = 8'hF0;
    localparam ADDR_BALL_Y           = 8'hF1;
    localparam ADDR_BALL_X_DIRECTION = 8'hF2;
    localparam ADDR_BALL_Y_DIRECTION = 8'hF3;
    localparam ADDR_BALL_SPEED       = 8'hF4;

    localparam ADDR_PLAYER_Y         = 8'hF5;
    localparam ADDR_PLAYER_SCORE     = 8'hF6;

    localparam ADDR_AI_Y             = 8'hF7;
    localparam ADDR_AI_SCORE         = 8'hF8;

    localparam ADDR_GAME_PAUSED      = 8'hF9;
    localparam ADDR_GAME_RESET       = 8'hFA;
    localparam ADDR_GAME_OVER        = 8'hFB;

    localparam ADDR_KEY_PRESSED      = 8'hFC;
    localparam ADDR_FRAME_READY      = 8'hFD;

    //============================================================
    // Game update divider
    //
    // frameTick happens once per VGA frame.
    // FRAME_DIVIDER_MAX = 2 means the CPU gets a game update
    // once every 3 frames.
    //
    // 0 -> wait
    // 1 -> wait
    // 2 -> set Frame_Ready
    //============================================================

    localparam FRAME_DIVIDER_MAX = 3'd2;

    reg [2:0] frameDivider;


    //============================================================
    // Write logic and frame-ready generation
    //============================================================

    always @(posedge clk) begin
        if (reset) begin

            ball_X           <= 16'd60;
            ball_Y           <= 16'd60;
            ball_X_Direction <= 16'd1;   // 0 = left, 1 = right
            ball_Y_Direction <= 16'd1;   // 0 = up,   1 = down
            ball_Speed       <= 16'd1;

            player_Y         <= 16'd50;
            player_Score     <= 16'd0;

            AI_Y             <= 16'd50;
            AI_Score         <= 16'd0;

            game_Paused      <= 16'd0;
            game_Reset       <= 16'd0;
            game_Over        <= 16'd0;

            Frame_Ready      <= 16'd0;
            frameDivider     <= 3'd0;
        end

        else begin

            if (writeEnable) begin
                case (writeAddress)

                    ADDR_BALL_X: begin
                        ball_X <= writeData;
                    end

                    ADDR_BALL_Y: begin
                        ball_Y <= writeData;
                    end

                    ADDR_BALL_X_DIRECTION: begin
                        ball_X_Direction <= writeData;
                    end

                    ADDR_BALL_Y_DIRECTION: begin
                        ball_Y_Direction <= writeData;
                    end

                    ADDR_BALL_SPEED: begin
                        ball_Speed <= writeData;
                    end

                    ADDR_PLAYER_Y: begin
                        player_Y <= writeData;
                    end

                    ADDR_PLAYER_SCORE: begin
                        player_Score <= writeData;
                    end

                    ADDR_AI_Y: begin
                        AI_Y <= writeData;
                    end

                    ADDR_AI_SCORE: begin
                        AI_Score <= writeData;
                    end

                    ADDR_GAME_PAUSED: begin
                        game_Paused <= writeData;
                    end

                    ADDR_GAME_RESET: begin
                        game_Reset <= writeData;
                    end

                    ADDR_GAME_OVER: begin
                        game_Over <= writeData;
                    end

                    ADDR_FRAME_READY: begin
                        // CPU writes 0 here after it has handled the update.
                        Frame_Ready <= writeData;
                    end

                    default: begin
                        // Ignore unknown writes.
                    end

                endcase
            end

            // Hardware sets Frame_Ready every few VGA frames.
            // This slows the game down without needing fractional ball speed.
            if (frameTick) begin
                if (frameDivider == FRAME_DIVIDER_MAX) begin
                    frameDivider <= 3'd0;
                    Frame_Ready  <= 16'd1;
                end
                else begin
                    frameDivider <= frameDivider + 3'd1;
                end
            end

        end
    end


    //============================================================
    // Read port 1
    //============================================================

    always @(*) begin
        case (readAddress1)

            ADDR_BALL_X: begin
                readData1 = ball_X;
            end

            ADDR_BALL_Y: begin
                readData1 = ball_Y;
            end

            ADDR_BALL_X_DIRECTION: begin
                readData1 = ball_X_Direction;
            end

            ADDR_BALL_Y_DIRECTION: begin
                readData1 = ball_Y_Direction;
            end

            ADDR_BALL_SPEED: begin
                readData1 = ball_Speed;
            end

            ADDR_PLAYER_Y: begin
                readData1 = player_Y;
            end

            ADDR_PLAYER_SCORE: begin
                readData1 = player_Score;
            end

            ADDR_AI_Y: begin
                readData1 = AI_Y;
            end

            ADDR_AI_SCORE: begin
                readData1 = AI_Score;
            end

            ADDR_GAME_PAUSED: begin
                readData1 = game_Paused;
            end

            ADDR_GAME_RESET: begin
                readData1 = game_Reset;
            end

            ADDR_GAME_OVER: begin
                readData1 = game_Over;
            end

            ADDR_KEY_PRESSED: begin
                readData1 = {12'd0, keyState};
            end

            ADDR_FRAME_READY: begin
                readData1 = Frame_Ready;
            end

            default: begin
                readData1 = 16'd0;
            end

        endcase
    end


    //============================================================
    // Read port 2
    //============================================================

    always @(*) begin
        case (readAddress2)

            ADDR_BALL_X: begin
                readData2 = ball_X;
            end

            ADDR_BALL_Y: begin
                readData2 = ball_Y;
            end

            ADDR_BALL_X_DIRECTION: begin
                readData2 = ball_X_Direction;
            end

            ADDR_BALL_Y_DIRECTION: begin
                readData2 = ball_Y_Direction;
            end

            ADDR_BALL_SPEED: begin
                readData2 = ball_Speed;
            end

            ADDR_PLAYER_Y: begin
                readData2 = player_Y;
            end

            ADDR_PLAYER_SCORE: begin
                readData2 = player_Score;
            end

            ADDR_AI_Y: begin
                readData2 = AI_Y;
            end

            ADDR_AI_SCORE: begin
                readData2 = AI_Score;
            end

            ADDR_GAME_PAUSED: begin
                readData2 = game_Paused;
            end

            ADDR_GAME_RESET: begin
                readData2 = game_Reset;
            end

            ADDR_GAME_OVER: begin
                readData2 = game_Over;
            end

            ADDR_KEY_PRESSED: begin
                readData2 = {12'd0, keyState};
            end

            ADDR_FRAME_READY: begin
                readData2 = Frame_Ready;
            end

            default: begin
                readData2 = 16'd0;
            end

        endcase
    end

endmodule