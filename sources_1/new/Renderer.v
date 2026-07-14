
module Renderer(

    input wire [9:0] xCoordinate,
    input wire [9:0] yCoordinate,
    input wire       activeVideo,

    input wire [15:0] ball_X,
    input wire [15:0] ball_Y,
    input wire [15:0] player_Y,
    input wire [15:0] AI_Y,

    input wire [15:0] player_Score,
    input wire [15:0] AI_Score,

    input wire [15:0] game_Paused,
    input wire [15:0] game_Over,

    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
);


    localparam PADDLE_WIDTH  = 8;
    localparam PADDLE_HEIGHT = 64;
    localparam BALL_SIZE     = 8;

    localparam PLAYER_X = 20;
    localparam AI_X     = 612;

    // Score digit constants
    localparam DIGIT_W = 40;
    localparam DIGIT_H = 70;
    localparam DIGIT_T = 8;

    localparam PLAYER_SCORE_X = 220;
    localparam AI_SCORE_X     = 390;
    localparam SCORE_Y        = 30;

    wire [9:0] ballXPixel   = {ball_X[7:0], 2'b00};
    wire [9:0] ballYPixel   = {ball_Y[7:0], 2'b00};
    wire [9:0] playerYPixel = {player_Y[7:0], 2'b00};
    wire [9:0] AIYPixel     = {AI_Y[7:0], 2'b00};

    wire insideBall;
    wire insidePlayerPaddle;
    wire insideAIPaddle;
    wire insideCenterLine;

    assign insideBall =
        (xCoordinate >= ballXPixel) &&
        (xCoordinate <  ballXPixel + BALL_SIZE) &&
        (yCoordinate >= ballYPixel) &&
        (yCoordinate <  ballYPixel + BALL_SIZE);

    assign insidePlayerPaddle =
        (xCoordinate >= PLAYER_X) &&
        (xCoordinate <  PLAYER_X + PADDLE_WIDTH) &&
        (yCoordinate >= playerYPixel) &&
        (yCoordinate <  playerYPixel + PADDLE_HEIGHT);

    assign insideAIPaddle =
        (xCoordinate >= AI_X) &&
        (xCoordinate <  AI_X + PADDLE_WIDTH) &&
        (yCoordinate >= AIYPixel) &&
        (yCoordinate <  AIYPixel + PADDLE_HEIGHT);

    assign insideCenterLine =
        (xCoordinate >= 318) &&
        (xCoordinate <  322) &&
        (yCoordinate[4] == 1'b0);

    //============================================================
    // 7-segment style digit renderer
    //
    // Segment order:
    // [6] = A top
    // [5] = B upper-right
    // [4] = C lower-right
    // [3] = D bottom
    // [2] = E lower-left
    // [1] = F upper-left
    // [0] = G middle
    //============================================================

    function [6:0] digitSegments;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: digitSegments = 7'b1111110;
                4'd1: digitSegments = 7'b0110000;
                4'd2: digitSegments = 7'b1101101;
                4'd3: digitSegments = 7'b1111001;
                4'd4: digitSegments = 7'b0110011;
                4'd5: digitSegments = 7'b1011011;
                4'd6: digitSegments = 7'b1011111;
                4'd7: digitSegments = 7'b1110000;
                4'd8: digitSegments = 7'b1111111;
                4'd9: digitSegments = 7'b1111011;
                default: digitSegments = 7'b0000001;
            endcase
        end
    endfunction

    function drawDigit;
        input [3:0] digit;
        input [9:0] x;
        input [9:0] y;
        input [9:0] originX;
        input [9:0] originY;

        reg [9:0] localX;
        reg [9:0] localY;
        reg [6:0] segments;

        reg segA;
        reg segB;
        reg segC;
        reg segD;
        reg segE;
        reg segF;
        reg segG;

        begin
            drawDigit = 1'b0;

            if ((x >= originX) && (x < originX + DIGIT_W) &&
                (y >= originY) && (y < originY + DIGIT_H)) begin

                localX = x - originX;
                localY = y - originY;

                segments = digitSegments(digit);

                segA = segments[6] &&
                       (localY < DIGIT_T) &&
                       (localX >= DIGIT_T) &&
                       (localX < DIGIT_W - DIGIT_T);

                segB = segments[5] &&
                       (localX >= DIGIT_W - DIGIT_T) &&
                       (localY >= DIGIT_T) &&
                       (localY < DIGIT_H / 2);

                segC = segments[4] &&
                       (localX >= DIGIT_W - DIGIT_T) &&
                       (localY >= DIGIT_H / 2) &&
                       (localY < DIGIT_H - DIGIT_T);

                segD = segments[3] &&
                       (localY >= DIGIT_H - DIGIT_T) &&
                       (localX >= DIGIT_T) &&
                       (localX < DIGIT_W - DIGIT_T);

                segE = segments[2] &&
                       (localX < DIGIT_T) &&
                       (localY >= DIGIT_H / 2) &&
                       (localY < DIGIT_H - DIGIT_T);

                segF = segments[1] &&
                       (localX < DIGIT_T) &&
                       (localY >= DIGIT_T) &&
                       (localY < DIGIT_H / 2);

                segG = segments[0] &&
                       (localY >= (DIGIT_H / 2) - (DIGIT_T / 2)) &&
                       (localY <  (DIGIT_H / 2) + (DIGIT_T / 2)) &&
                       (localX >= DIGIT_T) &&
                       (localX < DIGIT_W - DIGIT_T);

                drawDigit = segA || segB || segC || segD || segE || segF || segG;
            end
        end
    endfunction

    wire insidePlayerScore;
    wire insideAIScore;

    assign insidePlayerScore =
        drawDigit(player_Score[3:0],
                  xCoordinate,
                  yCoordinate,
                  PLAYER_SCORE_X,
                  SCORE_Y);

    assign insideAIScore =
        drawDigit(AI_Score[3:0],
                  xCoordinate,
                  yCoordinate,
                  AI_SCORE_X,
                  SCORE_Y);

    always @(*) begin

        // Default
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (!activeVideo) begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h0;
        end

        else if (game_Over[0]) begin
            vgaRed   = 4'h8;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h0;
        end

        else if (insideBall) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end

        else if (insidePlayerPaddle) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end

        else if (insideAIPaddle) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end

        else if (insidePlayerScore || insideAIScore) begin
            vgaRed   = 4'hF;
            vgaGreen = 4'hF;
            vgaBlue  = 4'hF;
        end

        else if (insideCenterLine) begin
            vgaRed   = 4'h5;
            vgaGreen = 4'h5;
            vgaBlue  = 4'h5;
        end

        else if (game_Paused[0]) begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h4;
        end

        else begin
            vgaRed   = 4'h0;
            vgaGreen = 4'h0;
            vgaBlue  = 4'h0;
        end

    end

endmodule