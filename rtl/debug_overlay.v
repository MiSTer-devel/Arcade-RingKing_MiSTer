module debug_overlay #(
    parameter COLS  = 6,
    parameter LINES = 4
)(
    input         clk,
    input         ce_pix,
    input         hblank,
    input         vblank,
    input  [2:0]  red_in,
    input  [2:0]  green_in,
    input  [1:0]  blue_in,
    output [2:0]  red_out,
    output [2:0]  green_out,
    output [1:0]  blue_out,
    input         ena,
    input  [COLS*5-1:0] in0,
    input  [COLS*5-1:0] in1,
    input  [COLS*5-1:0] in2,
    input  [COLS*5-1:0] in3
);

    reg [COLS*5-1:0] vin0, vin1, vin2, vin3;

    always @(posedge clk) begin
        if (hblank && vblank) begin
            vin0 <= in0;
            vin1 <= in1;
            vin2 <= in2;
            vin3 <= in3;
        end
    end

    reg [7:0] chars [0:255];

    initial begin
        chars[  0] = 8'h3E; chars[  1] = 8'h63; chars[  2] = 8'h73; chars[  3] = 8'h7B;
        chars[  4] = 8'h6F; chars[  5] = 8'h67; chars[  6] = 8'h3E; chars[  7] = 8'h00;
        chars[  8] = 8'h0C; chars[  9] = 8'h0E; chars[ 10] = 8'h0C; chars[ 11] = 8'h0C;
        chars[ 12] = 8'h0C; chars[ 13] = 8'h0C; chars[ 14] = 8'h3F; chars[ 15] = 8'h00;
        chars[ 16] = 8'h1E; chars[ 17] = 8'h33; chars[ 18] = 8'h30; chars[ 19] = 8'h1C;
        chars[ 20] = 8'h06; chars[ 21] = 8'h33; chars[ 22] = 8'h3F; chars[ 23] = 8'h00;
        chars[ 24] = 8'h1E; chars[ 25] = 8'h33; chars[ 26] = 8'h30; chars[ 27] = 8'h1C;
        chars[ 28] = 8'h30; chars[ 29] = 8'h33; chars[ 30] = 8'h1E; chars[ 31] = 8'h00;
        chars[ 32] = 8'h38; chars[ 33] = 8'h3C; chars[ 34] = 8'h36; chars[ 35] = 8'h33;
        chars[ 36] = 8'h7F; chars[ 37] = 8'h30; chars[ 38] = 8'h78; chars[ 39] = 8'h00;
        chars[ 40] = 8'h3F; chars[ 41] = 8'h03; chars[ 42] = 8'h1F; chars[ 43] = 8'h30;
        chars[ 44] = 8'h30; chars[ 45] = 8'h33; chars[ 46] = 8'h1E; chars[ 47] = 8'h00;
        chars[ 48] = 8'h1C; chars[ 49] = 8'h06; chars[ 50] = 8'h03; chars[ 51] = 8'h1F;
        chars[ 52] = 8'h33; chars[ 53] = 8'h33; chars[ 54] = 8'h1E; chars[ 55] = 8'h00;
        chars[ 56] = 8'h3F; chars[ 57] = 8'h33; chars[ 58] = 8'h30; chars[ 59] = 8'h18;
        chars[ 60] = 8'h0C; chars[ 61] = 8'h0C; chars[ 62] = 8'h0C; chars[ 63] = 8'h00;
        chars[ 64] = 8'h1E; chars[ 65] = 8'h33; chars[ 66] = 8'h33; chars[ 67] = 8'h1E;
        chars[ 68] = 8'h33; chars[ 69] = 8'h33; chars[ 70] = 8'h1E; chars[ 71] = 8'h00;
        chars[ 72] = 8'h1E; chars[ 73] = 8'h33; chars[ 74] = 8'h33; chars[ 75] = 8'h3E;
        chars[ 76] = 8'h30; chars[ 77] = 8'h18; chars[ 78] = 8'h0E; chars[ 79] = 8'h00;
        chars[ 80] = 8'h0C; chars[ 81] = 8'h1E; chars[ 82] = 8'h33; chars[ 83] = 8'h33;
        chars[ 84] = 8'h3F; chars[ 85] = 8'h33; chars[ 86] = 8'h33; chars[ 87] = 8'h00;
        chars[ 88] = 8'h3F; chars[ 89] = 8'h66; chars[ 90] = 8'h66; chars[ 91] = 8'h3E;
        chars[ 92] = 8'h66; chars[ 93] = 8'h66; chars[ 94] = 8'h3F; chars[ 95] = 8'h00;
        chars[ 96] = 8'h3C; chars[ 97] = 8'h66; chars[ 98] = 8'h03; chars[ 99] = 8'h03;
        chars[100] = 8'h03; chars[101] = 8'h66; chars[102] = 8'h3C; chars[103] = 8'h00;
        chars[104] = 8'h1F; chars[105] = 8'h36; chars[106] = 8'h66; chars[107] = 8'h66;
        chars[108] = 8'h66; chars[109] = 8'h36; chars[110] = 8'h1F; chars[111] = 8'h00;
        chars[112] = 8'h7F; chars[113] = 8'h46; chars[114] = 8'h16; chars[115] = 8'h1E;
        chars[116] = 8'h16; chars[117] = 8'h46; chars[118] = 8'h7F; chars[119] = 8'h00;
        chars[120] = 8'h7F; chars[121] = 8'h46; chars[122] = 8'h16; chars[123] = 8'h1E;
        chars[124] = 8'h16; chars[125] = 8'h06; chars[126] = 8'h0F; chars[127] = 8'h00;
        chars[128] = 8'h00; chars[129] = 8'h00; chars[130] = 8'h00; chars[131] = 8'h00;
        chars[132] = 8'h00; chars[133] = 8'h00; chars[134] = 8'h00; chars[135] = 8'h00;
        chars[136] = 8'h00; chars[137] = 8'h00; chars[138] = 8'h3F; chars[139] = 8'h00;
        chars[140] = 8'h00; chars[141] = 8'h3F; chars[142] = 8'h00; chars[143] = 8'h00;
        chars[144] = 8'h00; chars[145] = 8'h0C; chars[146] = 8'h0C; chars[147] = 8'h3F;
        chars[148] = 8'h0C; chars[149] = 8'h0C; chars[150] = 8'h00; chars[151] = 8'h00;
        chars[152] = 8'h00; chars[153] = 8'h00; chars[154] = 8'h00; chars[155] = 8'h3F;
        chars[156] = 8'h00; chars[157] = 8'h00; chars[158] = 8'h00; chars[159] = 8'h00;
        chars[160] = 8'h18; chars[161] = 8'h0C; chars[162] = 8'h06; chars[163] = 8'h03;
        chars[164] = 8'h06; chars[165] = 8'h0C; chars[166] = 8'h18; chars[167] = 8'h00;
        chars[168] = 8'h06; chars[169] = 8'h0C; chars[170] = 8'h18; chars[171] = 8'h30;
        chars[172] = 8'h18; chars[173] = 8'h0C; chars[174] = 8'h06; chars[175] = 8'h00;
        chars[176] = 8'h08; chars[177] = 8'h1C; chars[178] = 8'h36; chars[179] = 8'h63;
        chars[180] = 8'h41; chars[181] = 8'h00; chars[182] = 8'h00; chars[183] = 8'h00;
        chars[184] = 8'h08; chars[185] = 8'h1C; chars[186] = 8'h36; chars[187] = 8'h63;
        chars[188] = 8'h41; chars[189] = 8'h00; chars[190] = 8'h00; chars[191] = 8'h00;
        chars[192] = 8'h18; chars[193] = 8'h0C; chars[194] = 8'h06; chars[195] = 8'h06;
        chars[196] = 8'h06; chars[197] = 8'h0C; chars[198] = 8'h18; chars[199] = 8'h00;
        chars[200] = 8'h06; chars[201] = 8'h0C; chars[202] = 8'h18; chars[203] = 8'h18;
        chars[204] = 8'h18; chars[205] = 8'h0C; chars[206] = 8'h06; chars[207] = 8'h00;
        chars[208] = 8'h00; chars[209] = 8'h0C; chars[210] = 8'h0C; chars[211] = 8'h00;
        chars[212] = 8'h00; chars[213] = 8'h0C; chars[214] = 8'h0C; chars[215] = 8'h00;
        chars[216] = 8'h41; chars[217] = 8'h43; chars[218] = 8'h45; chars[219] = 8'h49;
        chars[220] = 8'h51; chars[221] = 8'h61; chars[222] = 8'h41; chars[223] = 8'h00;
        chars[224] = 8'h3E; chars[225] = 8'h41; chars[226] = 8'h41; chars[227] = 8'h41;
        chars[228] = 8'h41; chars[229] = 8'h41; chars[230] = 8'h3E; chars[231] = 8'h00;
        chars[232] = 8'h3F; chars[233] = 8'h41; chars[234] = 8'h41; chars[235] = 8'h3F;
        chars[236] = 8'h11; chars[237] = 8'h21; chars[238] = 8'h41; chars[239] = 8'h00;
        chars[240] = 8'h41; chars[241] = 8'h63; chars[242] = 8'h55; chars[243] = 8'h49;
        chars[244] = 8'h41; chars[245] = 8'h41; chars[246] = 8'h41; chars[247] = 8'h00;
        chars[248] = 8'h36; chars[249] = 8'h36; chars[250] = 8'h7F; chars[251] = 8'h36;
        chars[252] = 8'h7F; chars[253] = 8'h36; chars[254] = 8'h36; chars[255] = 8'h00;
    end

    reg [9:0] hpos = 0;
    reg [9:0] vpos = 0;
    reg hblank_prev = 0;
    wire hblank_rise = hblank & ~hblank_prev;

    always @(posedge clk) begin
        hblank_prev <= hblank;
        if (vblank) begin
            vpos <= 0;
            hpos <= 0;
        end else if (hblank_rise) begin
            hpos <= 0;
            vpos <= vpos + 10'd1;
        end else if (ce_pix) begin
            hpos <= hpos + 10'd1;
        end
    end

    wire [2:0] char_col = hpos[5:3];
    wire [2:0] char_row = vpos[5:3];
    wire [2:0] pix_x   = hpos[2:0];
    wire [2:0] pix_y   = vpos[2:0];

    wire in_zone = (char_col < COLS[2:0]) && (char_row < LINES[2:0]);

    reg [4:0] char_vin0, char_vin1, char_vin2, char_vin3;
    always @(*) begin
        case (char_col)
            3'd0: begin char_vin0 = vin0[ 4: 0]; char_vin1 = vin1[ 4: 0]; char_vin2 = vin2[ 4: 0]; char_vin3 = vin3[ 4: 0]; end
            3'd1: begin char_vin0 = vin0[ 9: 5]; char_vin1 = vin1[ 9: 5]; char_vin2 = vin2[ 9: 5]; char_vin3 = vin3[ 9: 5]; end
            3'd2: begin char_vin0 = vin0[14:10]; char_vin1 = vin1[14:10]; char_vin2 = vin2[14:10]; char_vin3 = vin3[14:10]; end
            3'd3: begin char_vin0 = vin0[19:15]; char_vin1 = vin1[19:15]; char_vin2 = vin2[19:15]; char_vin3 = vin3[19:15]; end
            3'd4: begin char_vin0 = vin0[24:20]; char_vin1 = vin1[24:20]; char_vin2 = vin2[24:20]; char_vin3 = vin3[24:20]; end
            3'd5: begin char_vin0 = vin0[29:25]; char_vin1 = vin1[29:25]; char_vin2 = vin2[29:25]; char_vin3 = vin3[29:25]; end
            default: begin char_vin0 = 5'd16; char_vin1 = 5'd16; char_vin2 = 5'd16; char_vin3 = 5'd16; end
        endcase
    end

    wire [4:0] char_sel = (char_row == 3'd0) ? char_vin0 :
                           (char_row == 3'd1) ? char_vin1 :
                           (char_row == 3'd2) ? char_vin2 :
                                                 char_vin3;

    wire [4:0] char_v = in_zone ? char_sel : 5'd16;

    reg [7:0] font_data;
    always @(*) begin
        font_data = chars[{char_v, pix_y}];
    end

    reg [2:0] r_pipe [0:2];
    reg [2:0] g_pipe [0:2];
    reg [1:0] b_pipe [0:2];
    reg       active [0:2];

    always @(posedge clk) begin
        r_pipe[0] <= red_in;   g_pipe[0] <= green_in;   b_pipe[0] <= blue_in;
        r_pipe[1] <= r_pipe[0]; g_pipe[1] <= g_pipe[0]; b_pipe[1] <= b_pipe[0];
        r_pipe[2] <= r_pipe[1]; g_pipe[2] <= g_pipe[1]; b_pipe[2] <= b_pipe[1];
        active[0] <= ena && in_zone && font_data[pix_x];
        active[1] <= active[0];
        active[2] <= active[1];
    end

    assign red_out   = active[2] ? 3'b111 : r_pipe[2];
    assign green_out = active[2] ? 3'b111 : g_pipe[2];
    assign blue_out  = active[2] ? 2'b11  : b_pipe[2];

endmodule
