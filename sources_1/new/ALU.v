//////////////////////////////////////////////////////////////////////////////////
// Creator: Zayaan 
// 
// Module Name: ALU
// Project Name: CPUWithPongIntergration
// Target Devices: Basys3
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(

    output reg zeroFlag,
    output reg carryFlag,

    input wire [15:0] A,
    input wire [15:0] B,

    output reg [15:0] computed,

    input wire [3:0] operation
    
 /*///////////////////////////////////////////////
0000 = ADD       A + B
0001 = SUB       A - B
0010 = AND       A & B
0011 = OR        A | B
0100 = XOR       A ^ B
0101 = NOT_A     ~A
0110 = SHL       A << 1
0111 = SHR       A >> 1
1000 = INC_A     A + 1
1001 = DEC_A     A - 1
1010 = PASS_A    A
1011 = PASS_B    B
1100 = ZERO      0
1101 = CMP       A - B, update flags only
1110 = NAND      ~(A & B)
1111 = NOR       ~(A | B)
*//////////////////////////////////////////////////

);

    localparam ADD    = 4'b0000;
    localparam SUB    = 4'b0001;
    localparam AND_OP = 4'b0010;
    localparam OR_OP  = 4'b0011;
    localparam XOR_OP = 4'b0100;
    localparam NOT_A  = 4'b0101;
    localparam SHL    = 4'b0110;
    localparam SHR    = 4'b0111;

    localparam INC_A  = 4'b1000;
    localparam DEC_A  = 4'b1001;
    localparam PASS_A = 4'b1010;
    localparam PASS_B = 4'b1011;
    localparam ZERO   = 4'b1100;
    localparam CMP    = 4'b1101;
    localparam NAND_OP = 4'b1110;
    localparam NOR_OP  = 4'b1111;

    reg [16:0] temp;
    
    always @(*) begin

        computed  = 16'd0;
        carryFlag = 1'b0;
        temp      = 17'd0;

        case(operation)

            ADD: begin
                temp      = {1'b0, A} + {1'b0, B};
                computed  = temp[15:0];
                carryFlag = temp[16];
            end

            SUB: begin
                temp      = {1'b0, A} - {1'b0, B};
                computed  = temp[15:0];
                carryFlag = temp[16];  //A > B
            end

            AND_OP: begin
                computed = A & B;
            end

            OR_OP: begin
                computed = A | B;
            end

            XOR_OP: begin
                computed = A ^ B;
            end

            NOT_A: begin
                computed = ~A;
            end

            SHL: begin
                computed  = A << 1;
                carryFlag = A[15];      // bit shifted out
            end

            SHR: begin
                computed  = A >> 1;
                carryFlag = A[0];       // bit shifted out
            end

            INC_A: begin
                temp      = {1'b0, A} + 17'd1;
                computed  = temp[15:0];
                carryFlag = temp[16];
            end

            DEC_A: begin
                temp      = {1'b0, A} - 17'd1;
                computed  = temp[15:0];
                carryFlag = temp[16];   //A > B
            end

            PASS_A: begin
                computed = A;
            end

            PASS_B: begin
                computed = B;
            end

            ZERO: begin
                computed = 16'd0;
            end

            CMP: begin
                temp      = {1'b0, A} - {1'b0, B};
                computed  = temp[15:0]; 
                carryFlag = temp[16];   
            end

            NAND_OP: begin
                computed = ~(A & B);
            end

            NOR_OP: begin
                computed = ~(A | B);
            end

            default: begin
                computed  = 16'd0;
                carryFlag = 1'b0;
            end

        endcase

        zeroFlag = (computed == 16'd0);

    end
endmodule
