//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: Instruction_Memory
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: Pong program ROM with paddle/wall collision and speed-up on hits
// 
//////////////////////////////////////////////////////////////////////////////////

module Instruction_Memory(
    input  wire [7:0]  address,
    output reg  [15:0] instruction
);


    // Non-ALU opcodes
    localparam OP_NOP   = 4'b0000;
    localparam OP_LDI   = 4'b0001;
    localparam OP_LOAD  = 4'b0010;
    localparam OP_STORE = 4'b0011;
    localparam OP_JMP   = 4'b0100;
    localparam OP_JZ    = 4'b0101;
    localparam OP_JNZ   = 4'b0110;
    localparam OP_JC    = 4'b0111;
    localparam OP_JNC   = 4'b1000;

    // ALU opcodes
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

    // Registers
    localparam R0  = 4'h0;
    localparam R1  = 4'h1;
    localparam R2  = 4'h2;
    localparam R3  = 4'h3;
    localparam R4  = 4'h4;
    localparam R5  = 4'h5;
    localparam R6  = 4'h6;
    localparam R7  = 4'h7;
    localparam R8  = 4'h8; // constant 1
    localparam R9  = 4'h9; // paddle height
    localparam R10 = 4'hA; // player collision X
    localparam R11 = 4'hB; // AI collision X
    localparam R12 = 4'hC; // bottom wall Y
    localparam R13 = 4'hD; // max paddle Y
    localparam R14 = 4'hE; // max ball speed
    localparam R15 = 4'hF;


    localparam MMIO_BALL_X           = 4'h0; // 0xF0
    localparam MMIO_BALL_Y           = 4'h1; // 0xF1
    localparam MMIO_BALL_X_DIRECTION = 4'h2; // 0xF2
    localparam MMIO_BALL_Y_DIRECTION = 4'h3; // 0xF3
    localparam MMIO_BALL_SPEED       = 4'h4; // 0xF4

    localparam MMIO_PLAYER_Y         = 4'h5; // 0xF5
    localparam MMIO_PLAYER_SCORE     = 4'h6; // 0xF6

    localparam MMIO_AI_Y             = 4'h7; // 0xF7
    localparam MMIO_AI_SCORE         = 4'h8; // 0xF8

    localparam MMIO_GAME_PAUSED      = 4'h9; // 0xF9
    localparam MMIO_GAME_RESET       = 4'hA; // 0xFA
    localparam MMIO_GAME_OVER        = 4'hB; // 0xFB

    localparam MMIO_KEY_PRESSED      = 4'hC; // 0xFC
    localparam MMIO_FRAME_READY      = 4'hD; // 0xFD;



    // Program labels
    localparam P_INIT                = 8'd0;
    localparam P_WAIT_FRAME          = 8'd27;
    localparam P_NOT_PAUSED          = 8'd43;
    localparam P_CHECK_DOWN          = 8'd54;
    localparam P_AI_UPDATE           = 8'd64;
    localparam P_AI_MOVE_DOWN        = 8'd75;
    localparam P_MOVE_X              = 8'd80;
    localparam P_CHECK_AI_PADDLE     = 8'd90;
    localparam P_MOVE_X_LEFT         = 8'd101;
    localparam P_LEFT_UNDERFLOW      = 8'd110;
    localparam P_CHECK_PLAYER_PADDLE = 8'd112;
    localparam P_MOVE_Y              = 8'd123;
    localparam P_MOVE_Y_UP           = 8'd133;
    localparam P_SET_Y_DOWN          = 8'd140;
    localparam P_SET_Y_UP            = 8'd143;
    localparam P_MAIN_END            = 8'd146;
    localparam P_PLAYER_SCORE        = 8'd147;
    localparam P_AI_SCORE            = 8'd152;
    localparam P_RESET_ROUND         = 8'd157;

    localparam P_AI_PADDLE_HIT       = 8'd168;
    localparam P_PLAYER_PADDLE_HIT   = 8'd176;


    //Assembly Definitions
    function [15:0] ENCODE_ALU;
        input [3:0] aluOp;
        input [3:0] regA;
        input [3:0] regB;
        begin
            ENCODE_ALU = {1'b1, aluOp, regA, regB, 3'b000};
        end
    endfunction

    function [15:0] ENCODE_LDI;
        input [3:0] regA;
        input [6:0] imm7;
        begin
            ENCODE_LDI = {1'b0, OP_LDI, regA, imm7};
        end
    endfunction

    function [15:0] ENCODE_MMIO;
        input [3:0] op;
        input [3:0] regA;
        input [3:0] mmioSelect;
        begin
            ENCODE_MMIO = {1'b0, op, regA, mmioSelect, 3'b000};
        end
    endfunction

    function [15:0] ENCODE_JUMP;
        input [3:0] op;
        input [7:0] target;
        begin
            ENCODE_JUMP = {1'b0, op, target, 3'b000};
        end
    endfunction


    always @(*) begin
        case (address)


            // INIT
            8'd0:   instruction = ENCODE_LDI(R0, 7'd0);
            8'd1:   instruction = ENCODE_LDI(R8, 7'd1);
            8'd2:   instruction = ENCODE_LDI(R9, 7'd16);
            8'd3:   instruction = ENCODE_LDI(R10, 7'd8);


            // AI paddle starts at VGA x = 612.
            8'd4:   instruction = ENCODE_LDI(R11, 7'd76);
            8'd5:   instruction = ENCODE_ALU(ALU_SHL, R11, R0);
            8'd6:   instruction = ENCODE_ALU(ALU_INC_A, R11, R0);
            8'd7:   instruction = ENCODE_LDI(R12, 7'd118);
            8'd8:   instruction = ENCODE_LDI(R13, 7'd104);
            8'd9:   instruction = ENCODE_LDI(R14, 7'd4);
            8'd10:  instruction = ENCODE_LDI(R1, 7'd80);
            8'd11:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_X);
            8'd12:  instruction = ENCODE_LDI(R1, 7'd60);
            8'd13:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_Y);
            8'd14:  instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_X_DIRECTION);
            8'd15:  instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_Y_DIRECTION);
            8'd16:  instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_SPEED);
            8'd17:  instruction = ENCODE_LDI(R1, 7'd52);
            8'd18:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_PLAYER_Y);
            8'd19:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_AI_Y);
            8'd20:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_PLAYER_SCORE);
            8'd21:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_AI_SCORE);
            8'd22:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_GAME_PAUSED);
            8'd23:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_GAME_RESET);
            8'd24:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_GAME_OVER);
            8'd25:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_FRAME_READY);
            8'd26:  instruction = ENCODE_JUMP(OP_JMP, P_WAIT_FRAME);


            // Wait frame
            8'd27:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_FRAME_READY);
            8'd28:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd29:  instruction = ENCODE_JUMP(OP_JZ, P_WAIT_FRAME);
            8'd30:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_FRAME_READY);

            //reset check
            8'd31:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_KEY_PRESSED);
            8'd32:  instruction = ENCODE_LDI(R2, 7'd4);
            8'd33:  instruction = ENCODE_ALU(ALU_AND, R1, R2);
            8'd34:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd35:  instruction = ENCODE_JUMP(OP_JNZ, P_INIT);

            //pause check
            8'd36:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_KEY_PRESSED);
            8'd37:  instruction = ENCODE_LDI(R2, 7'd8);
            8'd38:  instruction = ENCODE_ALU(ALU_AND, R1, R2);
            8'd39:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd40:  instruction = ENCODE_JUMP(OP_JZ, P_NOT_PAUSED);
            8'd41:  instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_GAME_PAUSED);
            8'd42:  instruction = ENCODE_JUMP(OP_JMP, P_WAIT_FRAME);
            8'd43:  instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_GAME_PAUSED);


            //player up
            8'd44:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_KEY_PRESSED);
            8'd45:  instruction = ENCODE_LDI(R2, 7'd1);
            8'd46:  instruction = ENCODE_ALU(ALU_AND, R1, R2);
            8'd47:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd48:  instruction = ENCODE_JUMP(OP_JZ, P_CHECK_DOWN);
            8'd49:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_PLAYER_Y);
            8'd50:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd51:  instruction = ENCODE_JUMP(OP_JZ, P_CHECK_DOWN);
            8'd52:  instruction = ENCODE_ALU(ALU_DEC_A, R1, R0);
            8'd53:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_PLAYER_Y);

            //player down
            8'd54:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_KEY_PRESSED);
            8'd55:  instruction = ENCODE_LDI(R2, 7'd2);
            8'd56:  instruction = ENCODE_ALU(ALU_AND, R1, R2);
            8'd57:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd58:  instruction = ENCODE_JUMP(OP_JZ, P_AI_UPDATE);
            8'd59:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_PLAYER_Y);
            8'd60:  instruction = ENCODE_ALU(ALU_CMP, R1, R13);
            8'd61:  instruction = ENCODE_JUMP(OP_JNC, P_AI_UPDATE);
            8'd62:  instruction = ENCODE_ALU(ALU_INC_A, R1, R0);
            8'd63:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_PLAYER_Y);


            //ai up
            8'd64:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_AI_Y);
            8'd65:  instruction = ENCODE_MMIO(OP_LOAD, R2, MMIO_BALL_Y);
            8'd66:  instruction = ENCODE_ALU(ALU_CMP, R1, R2);
            8'd67:  instruction = ENCODE_JUMP(OP_JZ, P_MOVE_X);
            8'd68:  instruction = ENCODE_JUMP(OP_JC, P_AI_MOVE_DOWN);
            8'd69:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_AI_Y);
            8'd70:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd71:  instruction = ENCODE_JUMP(OP_JZ, P_MOVE_X);
            8'd72:  instruction = ENCODE_ALU(ALU_DEC_A, R1, R0);
            8'd73:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_AI_Y);
            8'd74:  instruction = ENCODE_JUMP(OP_JMP, P_MOVE_X);
            8'd75:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_AI_Y);
            8'd76:  instruction = ENCODE_ALU(ALU_CMP, R1, R13);
            8'd77:  instruction = ENCODE_JUMP(OP_JNC, P_MOVE_X);
            8'd78:  instruction = ENCODE_ALU(ALU_INC_A, R1, R0);
            8'd79:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_AI_Y);

            
            //ball dir x
            8'd80:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_X_DIRECTION);
            8'd81:  instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd82:  instruction = ENCODE_JUMP(OP_JZ, P_MOVE_X_LEFT);
            8'd83:  instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_X);
            8'd84:  instruction = ENCODE_MMIO(OP_LOAD, R2, MMIO_BALL_SPEED);
            8'd85:  instruction = ENCODE_ALU(ALU_ADD, R1, R2);
            8'd86:  instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_X);
            8'd87:  instruction = ENCODE_ALU(ALU_CMP, R1, R11);
            8'd88:  instruction = ENCODE_JUMP(OP_JNC, P_CHECK_AI_PADDLE);
            8'd89:  instruction = ENCODE_JUMP(OP_JMP, P_MOVE_Y);



            // ai paddle colision
            8'd90:  instruction = ENCODE_MMIO(OP_LOAD, R3, MMIO_BALL_Y);
            8'd91:  instruction = ENCODE_MMIO(OP_LOAD, R4, MMIO_AI_Y);
            8'd92:  instruction = ENCODE_ALU(ALU_CMP, R3, R4);
            8'd93:  instruction = ENCODE_JUMP(OP_JC, P_PLAYER_SCORE);
            8'd94:  instruction = ENCODE_ALU(ALU_PASS_B, R5, R4);
            8'd95:  instruction = ENCODE_ALU(ALU_ADD, R5, R9);
            8'd96:  instruction = ENCODE_ALU(ALU_CMP, R3, R5);
            8'd97:  instruction = ENCODE_JUMP(OP_JNC, P_PLAYER_SCORE);
            8'd98:  instruction = ENCODE_JUMP(OP_JMP, P_AI_PADDLE_HIT);
            8'd99:  instruction = {1'b0, OP_NOP, 11'd0};
            8'd100: instruction = {1'b0, OP_NOP, 11'd0};


            // ai hit reflection
            8'd101: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_X);
            8'd102: instruction = ENCODE_MMIO(OP_LOAD, R2, MMIO_BALL_SPEED);

            8'd103: instruction = ENCODE_ALU(ALU_CMP, R1, R2);
            8'd104: instruction = ENCODE_JUMP(OP_JC, P_LEFT_UNDERFLOW);

            8'd105: instruction = ENCODE_ALU(ALU_SUB, R1, R2);
            8'd106: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_X);

            8'd107: instruction = ENCODE_ALU(ALU_CMP, R1, R10);
            8'd108: instruction = ENCODE_JUMP(OP_JC, P_CHECK_PLAYER_PADDLE);
            8'd109: instruction = ENCODE_JUMP(OP_JMP, P_MOVE_Y);

            8'd110: instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_BALL_X);
            8'd111: instruction = ENCODE_JUMP(OP_JMP, P_CHECK_PLAYER_PADDLE);


            //player collision
            8'd112: instruction = ENCODE_MMIO(OP_LOAD, R3, MMIO_BALL_Y);
            8'd113: instruction = ENCODE_MMIO(OP_LOAD, R4, MMIO_PLAYER_Y);
            8'd114: instruction = ENCODE_ALU(ALU_CMP, R3, R4);
            8'd115: instruction = ENCODE_JUMP(OP_JC, P_AI_SCORE);
            8'd116: instruction = ENCODE_ALU(ALU_PASS_B, R5, R4);
            8'd117: instruction = ENCODE_ALU(ALU_ADD, R5, R9);
            8'd118: instruction = ENCODE_ALU(ALU_CMP, R3, R5);
            8'd119: instruction = ENCODE_JUMP(OP_JNC, P_AI_SCORE);
            8'd120: instruction = ENCODE_JUMP(OP_JMP, P_PLAYER_PADDLE_HIT);
            8'd121: instruction = {1'b0, OP_NOP, 11'd0};
            8'd122: instruction = {1'b0, OP_NOP, 11'd0};


            //move dir y
            8'd123: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_Y_DIRECTION);
            8'd124: instruction = ENCODE_ALU(ALU_CMP, R1, R0);
            8'd125: instruction = ENCODE_JUMP(OP_JZ, P_MOVE_Y_UP);
            8'd126: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_Y);
            8'd127: instruction = ENCODE_MMIO(OP_LOAD, R2, MMIO_BALL_SPEED);
            8'd128: instruction = ENCODE_ALU(ALU_ADD, R1, R2);
            8'd129: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_Y);
            8'd130: instruction = ENCODE_ALU(ALU_CMP, R1, R12);
            8'd131: instruction = ENCODE_JUMP(OP_JNC, P_SET_Y_UP);
            8'd132: instruction = ENCODE_JUMP(OP_JMP, P_MAIN_END);
            8'd133: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_BALL_Y);
            8'd134: instruction = ENCODE_MMIO(OP_LOAD, R2, MMIO_BALL_SPEED);
            8'd135: instruction = ENCODE_ALU(ALU_CMP, R1, R2);
            8'd136: instruction = ENCODE_JUMP(OP_JC, P_SET_Y_DOWN);
            8'd137: instruction = ENCODE_ALU(ALU_SUB, R1, R2);
            8'd138: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_Y);
            8'd139: instruction = ENCODE_JUMP(OP_JMP, P_MAIN_END);


            
            //roof bounce
            8'd140: instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_Y_DIRECTION);
            8'd141: instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_BALL_Y);
            8'd142: instruction = ENCODE_JUMP(OP_JMP, P_MAIN_END);
            8'd143: instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_BALL_Y_DIRECTION);
            8'd144: instruction = ENCODE_MMIO(OP_STORE, R12, MMIO_BALL_Y);
            8'd145: instruction = ENCODE_JUMP(OP_JMP, P_MAIN_END);

            8'd146: instruction = ENCODE_JUMP(OP_JMP, P_WAIT_FRAME);

            //player score
            8'd147: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_PLAYER_SCORE);
            8'd148: instruction = ENCODE_ALU(ALU_INC_A, R1, R0);
            8'd149: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_PLAYER_SCORE);
            8'd150: instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_BALL_X_DIRECTION);
            8'd151: instruction = ENCODE_JUMP(OP_JMP, P_RESET_ROUND);

            //ai score
            8'd152: instruction = ENCODE_MMIO(OP_LOAD, R1, MMIO_AI_SCORE);
            8'd153: instruction = ENCODE_ALU(ALU_INC_A, R1, R0);
            8'd154: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_AI_SCORE);
            8'd155: instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_X_DIRECTION);
            8'd156: instruction = ENCODE_JUMP(OP_JMP, P_RESET_ROUND);

            
            //round reset
            8'd157: instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_SPEED);
            8'd158: instruction = ENCODE_LDI(R1, 7'd80);
            8'd159: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_X);
            8'd160: instruction = ENCODE_LDI(R1, 7'd60);
            8'd161: instruction = ENCODE_MMIO(OP_STORE, R1, MMIO_BALL_Y);
            8'd162: instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_Y_DIRECTION);
            8'd163: instruction = ENCODE_JUMP(OP_JMP, P_WAIT_FRAME);


            //====================================================
            // AI PADDLE HIT ROUTINE
            //
            // If speed < maxSpeed:
            //     speed++
            // Then bounce left.
            //====================================================

            8'd168: instruction = ENCODE_MMIO(OP_LOAD, R6, MMIO_BALL_SPEED);
            8'd169: instruction = ENCODE_ALU(ALU_CMP, R6, R14);
            8'd170: instruction = ENCODE_JUMP(OP_JNC, 8'd173);
            8'd171: instruction = ENCODE_ALU(ALU_INC_A, R6, R0);
            8'd172: instruction = ENCODE_MMIO(OP_STORE, R6, MMIO_BALL_SPEED);
            8'd173: instruction = ENCODE_MMIO(OP_STORE, R0, MMIO_BALL_X_DIRECTION);
            8'd174: instruction = ENCODE_MMIO(OP_STORE, R11, MMIO_BALL_X);
            8'd175: instruction = ENCODE_JUMP(OP_JMP, P_MOVE_Y);


            //====================================================
            // PLAYER PADDLE HIT ROUTINE
            //
            // If speed < maxSpeed:
            //     speed++
            // Then bounce right.
            //====================================================

            8'd176: instruction = ENCODE_MMIO(OP_LOAD, R6, MMIO_BALL_SPEED);
            8'd177: instruction = ENCODE_ALU(ALU_CMP, R6, R14);
            8'd178: instruction = ENCODE_JUMP(OP_JNC, 8'd181);
            8'd179: instruction = ENCODE_ALU(ALU_INC_A, R6, R0);
            8'd180: instruction = ENCODE_MMIO(OP_STORE, R6, MMIO_BALL_SPEED);
            8'd181: instruction = ENCODE_MMIO(OP_STORE, R8, MMIO_BALL_X_DIRECTION);
            8'd182: instruction = ENCODE_MMIO(OP_STORE, R10, MMIO_BALL_X);
            8'd183: instruction = ENCODE_JUMP(OP_JMP, P_MOVE_Y);


            //====================================================
            // Default
            //====================================================

            default: instruction = {1'b0, OP_NOP, 11'd0};

        endcase
    end

endmodule