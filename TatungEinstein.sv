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
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + USER_PP, USER_IN/OUT widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);
///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driver
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];     // 2P core: UserIO Players selector
wire         snac_active     = 1'b0;
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire         pad_1_6btn, pad_2_6btn;
wire  [15:0] joy_raw_payload;

joydb joydb (
  .clk             ( CLK_JOY         ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .pad_1_6btn      ( pad_1_6btn      ),
  .pad_2_6btn      ( pad_2_6btn      ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

// assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE= 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT =0;

assign AUDIO_S = 0;
//assign AUDIO_L = 0;
//assign AUDIO_R = 0;
assign AUDIO_MIX = 0;

assign LED_USER = 0;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[9:8];
wire [2:0] scale = status[5:3];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire scandoubler = (scale || forced_scandoubler);
wire freeze_sync;

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;
assign VGA_SL = sl[1:0];

`include "build_id.v" 
localparam CONF_STR = {
	"TatungEinstein;;",
	"S0,DSK,Mount Disk 0:;",
 	//"S1,DSK,Mount Disk 1:;",
	"-;",
	"O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"OA,Einstein Version,TC01,256;",
	"-;",
	"O2,Joystick,Digital,Analog;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players,1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"O6,Diagnostic ROM mounted,Off,On;",
	"O7,Border,Off,On;",
	"-;",
	"T0,Reset;",
	"R0,Reset and close OSD;",
	"V,v",`BUILD_DATE 
};

wire        direct_video;
wire [21:0] gamma_bus;
wire forced_scandoubler;
wire  [1:0] buttons;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: status widened to 128 bits
wire [127:0] status;
// [MiSTer-DB9 END]
wire [10:0] ps2_key;
wire [31:0] sd_lba;
wire  [1:0] sd_rd;
wire  [1:0] sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire  [1:0] img_mounted;
wire  [1:0] img_readonly;
wire [63:0] img_size;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joysticks renamed + joydb mux
wire [15:0] joystick_0_USB, joystick_1_USB;
wire [15:0] joystick_0 = joydb_1ena ? (OSD_STATUS ? 16'b0 : joydb_1) : joystick_0_USB;
wire [15:0] joystick_1 = joydb_2ena ? (OSD_STATUS ? 16'b0 : joydb_2) : (joydb_1ena ? joystick_0_USB : joystick_1_USB);
// [MiSTer-DB9 END]
wire [15:0] joystick_analog_0;
wire [15:0] joystick_analog_1;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),
	
	.ps2_key(ps2_key),


	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joysticks renamed
	.joystick_0(joystick_0_USB),
	.joystick_1(joystick_1_USB),
	// [MiSTer-DB9 END]
	.joystick_l_analog_0(joystick_analog_0),
	.joystick_l_analog_1(joystick_analog_1),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw for OSD autodetect
	.joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire clk_vdp;
wire clk_vid;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys), // 32
	.outclk_1(clk_vdp), // 10.6
	.outclk_2(clk_vid)  // 42.6
);

reg old_mode;
always @(posedge clk_sys) old_mode <= status[10];

wire reset = RESET | status[0] | buttons[1] | (old_mode^status[10]);

reg [2:0] clk_div;
wire clk_cpu = clk_div[2]; // 4M
wire clk_fdc = clk_div == 3'b111;
always @(posedge clk_sys) clk_div <= clk_div + 3'd1;


//////////////////////////////////////////////////////////////////

wire [7:0] kb_row;
wire [7:0] kb_col;
wire shift, ctrl, graph;
wire press_btn;

keyboard keyboard(
  .clk_sys(clk_sys),
  .reset(reset),
  .ps2_key(ps2_key),
  .addr(kb_row),
  .kb_cols(kb_col),
  .modif({ ctrl, graph, shift }),
  .press_btn(press_btn)
);

wire [9:0] sound;
assign AUDIO_L = { sound, 5'd0 };
assign AUDIO_R = { sound, 5'd0 };

tatung tatung
(
	.clk_sys(clk_sys),
	.clk_vdp(clk_vdp),
	.clk_cpu(clk_cpu),
	.clk_fdc(clk_fdc),
	.clk_vdp9938(clk_vdp9938),
	.reset(reset),

	.vga_red(vga_red),
	.vga_green(vga_green),
	.vga_blue(vga_blue),
	.vga_hblank(vga_hblank),
	.vga_vblank(vga_vblank),
	.vga_hsync(vga_hsync),
	.vga_vsync(vga_vsync),
	
	.sound(sound),
	
	.kb_row(kb_row),
	.kb_col(kb_col),
	.kb_shift(shift),
	.kb_ctrl(ctrl),
	.kb_graph(graph),
	.kb_down(press_btn),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(|sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_dout(sd_buff_dout),
	.sd_din(sd_buff_din),
	.sd_dout_strobe(sd_buff_wr),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_analog_0(joystick_analog_0),
   .joystick_analog_1(joystick_analog_1),

	.diagnostic(status[6]),
	.border(status[7]),
	.analog(status[2]),
	.m256(status[10]),
	.scandoubler(scandoubler)
);

wire [7:0] vga_red, vga_green, vga_blue;
wire vga_hsync, vga_vsync;
wire vga_hblank, vga_vblank;

assign CLK_VIDEO = clk_vid;
wire ce_pix = pxcnt[2];
reg [2:0] pxcnt;
reg clk_vdp9938;

always @(posedge clk_vid) begin
	clk_vdp9938 <= ~clk_vdp9938;
	pxcnt <= pxcnt + 3'd1;
end

video_mixer #(.GAMMA(1), .LINE_LENGTH(256)) video_mixer
(
   .*,

   .CLK_VIDEO(clk_vid),
   .ce_pix(ce_pix),

   .hq2x(scale==1),

   .R(vga_red),
   .G(vga_green),
   .B(vga_blue),

   .HSync(vga_hsync),
   .VSync(vga_vsync),
   .HBlank(vga_hblank),
   .VBlank(vga_vblank)
);


endmodule
