//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	`include "sys/emu_ports.vh"
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[9:8];

assign VIDEO_ARX = (!ar) ? 12'd3 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd4 : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"RingKing;;",
	"-;",
	"H0O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O5,Orientation,Vert,Horz;",
	"OFH,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"T[0],Reset;",
	"R[0],Reset and close OSD;",
	"v,0;",
	"V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire direct_video;
wire video_rotated;
wire   [1:0] buttons;
wire [127:0] status;
wire  [10:0] ps2_key;
wire  [21:0] gamma_bus;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire [15:0] ioctl_index;

wire [31:0] joystick_0;
wire [31:0] joystick_1;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.ps2_key(ps2_key)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys)
);

wire reset = RESET | status[0] | buttons[1] | ioctl_download;

//////////////////////   INPUTS   ///////////////////////////////

reg [7:0] sw[8];
always @(posedge clk_sys)
	if (ioctl_wr && (ioctl_index == 254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire [7:0] p1 = ~{
    2'b00,
    joystick_0[5],
    joystick_0[4],
    joystick_0[1],
    joystick_0[0],
    joystick_0[2],
    joystick_0[3]
};

wire [7:0] p2 = ~{
    2'b00,
    joystick_1[5],
    joystick_1[4],
    joystick_1[1],
    joystick_1[0],
    joystick_1[2],
    joystick_1[3]
};

wire [7:0] p3 = {
    2'b00,
    ~core_vb,
    1'b1,
    ~joystick_1[6],
    ~joystick_0[6],
    1'b1,
    ~joystick_0[7]
};

wire [7:0] dsw  = ~sw[0];
wire [7:0] dsw2 = ~sw[1];

//////////////////////   VIDEO   ////////////////////////////////

wire [2:0] core_red;
wire [2:0] core_green;
wire [1:0] core_blue;
wire core_vb, core_hb, core_vs, core_hs;
wire core_ce_pix;
wire [15:0] core_sound;
wire [7:0] video_raw = {core_red, core_green, core_blue};

core u_core(
	.clk_sys         ( clk_sys          ),
	.reset           ( reset            ),
	.p1              ( p1               ),
	.p2              ( p2               ),
	.p3              ( p3               ),
	.dsw             ( dsw              ),
	.dsw2            ( dsw2             ),
	.ioctl_download  ( ioctl_download   ),
	.ioctl_index     ( ioctl_index      ),
	.ioctl_addr      ( ioctl_addr[24:0] ),
	.ioctl_dout      ( ioctl_dout       ),
	.ioctl_wr        ( ioctl_wr         ),
	.red             ( core_red         ),
	.green           ( core_green       ),
	.blue            ( core_blue        ),
	.vb              ( core_vb          ),
	.hb              ( core_hb          ),
	.vs              ( core_vs          ),
	.hs              ( core_hs          ),
	.ce_pix          ( core_ce_pix      ),
	.sound           ( core_sound       ),
	.vflip           ( 1'b0             )
);

wire no_rotate = status[5];

arcade_video #(.WIDTH(256), .DW(8), .GAMMA(1)) arcade_video
(
	.clk_video(clk_sys),
	.ce_pix(core_ce_pix),

	.RGB_in(video_raw),
	.HBlank(core_hb),
	.VBlank(core_vb),
	.HSync(core_hs),
	.VSync(core_vs),

	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_DE(VGA_DE),
	.VGA_SL(VGA_SL),

	.fx(status[17:15]),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus)
);

screen_rotate screen_rotate
(
	.*,
	.rotate_ccw(1'b0),
	.no_rotate(no_rotate),
	.flip(1'b0)
);

//////////////////////   AUDIO   ////////////////////////////////

assign AUDIO_L = core_sound;
assign AUDIO_R = core_sound;
assign AUDIO_S = 1; // signed audio
assign AUDIO_MIX = 3; // 100% mono

//////////////////////   LED    /////////////////////////////////

reg [26:0] act_cnt;
always @(posedge clk_sys) act_cnt <= act_cnt + 1'd1;
assign LED_USER = act_cnt[26] ? act_cnt[25:18] > act_cnt[7:0] : act_cnt[25:18] <= act_cnt[7:0];

endmodule
