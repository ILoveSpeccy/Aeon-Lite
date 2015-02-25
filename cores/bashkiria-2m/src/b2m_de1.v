// ====================================================================
//                Bashkiria-2M FPGA REPLICA
//
//            Copyright (C) 2010 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Bashkiria-2M home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: b2m_de1.v
//
// Top-level design file of Bashkiria-2M replica.

module b2m_de1(
	input			clk50,

	inout	[15:0]	SRAM_DQ,				//	SRAM Data bus 16 Bits
	output	[17:0]	SRAM_ADDR,				//	SRAM Address bus 18 Bits
	output			SRAM_UB_N,				//	SRAM High-byte Data Mask 
	output			SRAM_LB_N,				//	SRAM Low-byte Data Mask 
	output			SRAM_WE_N,				//	SRAM Write Enable
	output			SRAM_CE_N,				//	SRAM Chip Enable
	output			SRAM_OE_N,				//	SRAM Output Enable

   output         SOUND_L,
   output         SOUND_R,
   
	output 			VGA_HS,
	output 			VGA_VS,
	output	[3:0] 	VGA_R,
	output	[3:0] 	VGA_G,
	output	[3:0] 	VGA_B,

	input			PS2_CLK,
	input			PS2_DAT,

	input			SD_DAT,					//	SD Card Data 			(MISO)
	output			SD_DAT3,				//	SD Card Data 3 			(CSn)
	output			SD_CMD,					//	SD Card Command Signal	(MOSI)
	output			SD_CLK					//	SD Card Clock			(SCK)
   );


////////////////////   RESET   ////////////////////
reg[3:0] reset_cnt;
reg reset_n;
wire reset = ~reset_n;
wire cpurst;

always @(posedge clk50) begin
   if (!cpurst && reset_cnt==4'd14)
		reset_n <= 1'b1;
	else begin
		reset_n <= 1'b0;
		reset_cnt <= reset_cnt+4'd1;
	end
end

////////////////////   MEM   ////////////////////
wire mapvpage = ^mmap[2:1] && addrbus[15:11]>=5'b00101 && addrbus[15:12]<4'b0111;
wire rom_oe = mmap==3'h7 || (mmap!=3'h6 && &addrbus[15:13]);
wire kbd_oe = mapvpage && addrbus[15:12]==4'b0010;
wire sram_msb = npage[0];
wire[2:0] mmap = ppa1_c[2:0];
wire[2:0] npage = mapvpage ? {1'b0,mmap[1:0]} : {1'b1,addrbus[15:14]};
wire[7:0] mem_o = sram_msb ? SRAM_DQ[15:8] : SRAM_DQ[7:0];
wire[7:0] rom_o;

assign SRAM_DQ[7:0]  = SRAM_WE_N| sram_msb ? 8'bZZZZZZZZ : cpu_o;
assign SRAM_DQ[15:8] = SRAM_WE_N|~sram_msb ? 8'bZZZZZZZZ : cpu_o;
assign SRAM_ADDR = vid_rd ? {3'b000,~ppa1_c[7],vid_addr[13:8],vid_addr[7:0]+ppa1_b} : {2'b00,npage[2:1],addrbus[13:0]};
assign SRAM_UB_N = vid_rd ? 1'b0 : ~sram_msb;
assign SRAM_LB_N = vid_rd ? 1'b0 : sram_msb;
assign SRAM_WE_N = vid_rd ? 1'b1 : cpu_wr_n|sysctl[4]|(|vid_state);
assign SRAM_OE_N = ~(vid_rd|cpu_rd);
assign SRAM_CE_N = 0;

bios rom(.addra(addrbus[12:0]), .clka(clk50), .douta(rom_o));

////////////////////   CPU   ////////////////////
wire[15:0] addrbus;
wire[7:0] cpu_o;
wire cpu_sync;
wire cpu_rd;
wire cpu_wr_n;
wire cpu_int;
wire cpu_inta_n;
reg[7:0] sysctl;
reg[7:0] cpu_i;
reg[7:0] port_o;

always @(posedge clk50)
	casex (addrbus[4:0])
	5'b000xx: port_o <= pit_o;
	5'b010xx: port_o <= ppa1_o;
	5'b1010x: port_o <= pic_o;
	5'b11011: port_o <= sd_o;
	default: port_o <= 0;
	endcase

wire port_wr_n = cpu_wr_n|~sysctl[4];
wire port_rd = cpu_rd&sysctl[6];
wire pit_we_n =  addrbus[4:2]!=3'b000|port_wr_n;
wire ppa1_we_n = addrbus[4:2]!=3'b010|port_wr_n;
wire pal_we_n  = addrbus[4:2]!=3'b100|port_wr_n;
wire pic_we_n  = addrbus[4:1]!=4'b1010|port_wr_n;
wire sio_we_n  = addrbus[4:1]!=4'b1100|port_wr_n;
wire pit_rd = addrbus[4:2]==3'b000&port_rd;

always @(*)
	casex ({~cpu_inta_n,sysctl[6],rom_oe,kbd_oe})
	4'b1xxx: cpu_i = pic_o;
	4'b01xx: cpu_i = port_o;
	4'b001x: cpu_i = rom_o;
	4'b0001: cpu_i = kbd_o;
	4'b0000: cpu_i = mem_o;
	endcase

reg sound_on;
reg cpu_flag;
reg[10:0] cpu_cnt;

wire cpu_ce = cpu_ce2;
wire cpu_ce2 = (cpu_flag^cpu_cnt[10]) && vid_state==0;

always @(posedge clk50) begin
	if (cpu_sync) sysctl <= cpu_o;
	if (addrbus[0]&~sio_we_n) sound_on <= ~cpu_o[5];
	cpu_cnt <= cpu_cnt + 11'd41;
	cpu_flag <= cpu_flag^cpu_ce2;
end

k580wm80a CPU(.clk(clk50), .ce(cpu_ce), .reset(reset),
	.idata(cpu_i), .addr(addrbus), .sync(cpu_sync), .rd(cpu_rd), .wr_n(cpu_wr_n),
	.intr(cpu_int), .inta_n(cpu_inta_n), .odata(cpu_o));

////////////////////   VIDEO   ////////////////////
wire vid_irq;
wire vid_drq;
wire[13:0] vid_addr;
reg[15:0] vid_data;
reg[1:0] vid_state;
reg vid_exdrq;

wire vid_rd = vid_state==2'b10;

always @(posedge clk50) begin
	vid_exdrq <= vid_drq;
	case (vid_state)
	2'b00: vid_state <= vid_drq && ~vid_exdrq ? 2'b01 : 2'b00;
	2'b01: vid_state <= 2'b10;
	2'b10: vid_state <= 2'b11;
	2'b11: vid_state <= 2'b00;
	endcase
	if(vid_rd) vid_data <= SRAM_DQ;
end

b2m_video video(.clk50(clk50), .hr(VGA_HS), .vr(VGA_VS), .vid_irq(vid_irq),
	.r(VGA_R), .g(VGA_G), .b(VGA_B), .drq(vid_drq), .addr(vid_addr), .idata(vid_data),
	.pal_idx(addrbus[1:0]), .pal_data(cpu_o), .pal_we_n(pal_we_n), .color_mode(1'b1), .mode(1'b0));

////////////////////   KBD   ////////////////////
wire[7:0] kbd_o;

b2m_kbd kbd(.clk(clk50), .reset(reset), .ps2_clk(PS2_CLK), .ps2_dat(PS2_DAT),
	.addr(addrbus[8:0]), .cpurst(cpurst), .odata(kbd_o));

////////////////////   SYS PPA   ////////////////////
wire[7:0] ppa1_o;
wire[7:0] ppa1_a;
wire[7:0] ppa1_b;
wire[7:0] ppa1_c;

k580ww55 ppa1(.clk(clk50), .reset(reset), .addr(addrbus[1:0]), .we_n(ppa1_we_n),
	.idata(cpu_o), .odata(ppa1_o), .ipa(ppa1_a), .opa(ppa1_a),
	.ipb(ppa1_b), .opb(ppa1_b), .ipc(ppa1_c), .opc(ppa1_c));

reg tapein;

////////////////////   PIT   ////////////////////
wire[7:0] pit_o;
wire pit_out0;
wire pit_out1;
wire pit_out2;

////////////////////   PIC   ////////////////////
wire[7:0] pic_o;

k580wn59 pic(.clk(clk50), .reset(reset), .addr(addrbus[0]), .we_n(pic_we_n),
	.idata(cpu_o), .odata(pic_o), .intr(cpu_int), .inta_n(cpu_inta_n),
	.irq({3'b0,tapein,2'b0,pit_out0,vid_irq}));
	

k580wi53 pit(.clk(clk50), .c0(pit_out2), .c1(cpu_ce), .c2(cpu_ce),
	.g0(1'b1), .g1(sound_on), .g2(1'b1), .out0(pit_out0), .out1(pit_out1), .out2(pit_out2),
	.addr(addrbus[1:0]), .rd(pit_rd), .we_n(pit_we_n), .idata(cpu_o), .odata(pit_o));

////////////////////   SOUND   ////////////////////
assign SOUND_L = reset ? 1'b0 : pit_out1 | ppa1_c[6];
assign SOUND_R = reset ? 1'b0 : pit_out1 | ppa1_c[6];

////////////////////   SD CARD   ////////////////////
reg sdcs;
reg sdclk;
reg sdcmd;
reg[6:0] sddata;
wire[7:0] sd_o = {sddata, SD_DAT};

assign SD_DAT3 = ~sdcs;
assign SD_CMD = sdcmd;
assign SD_CLK = sdclk;

always @(posedge clk50 or posedge reset) begin
	if (reset) begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'h1;
	end else begin
		if (addrbus[4:0]==5'h1A && ~port_wr_n) sdcs <= cpu_o[0];
		if (addrbus[4:0]==5'h1B && ~port_wr_n) begin
			if (sdclk) sddata <= {sddata[5:0],SD_DAT};
			sdcmd <= cpu_o[7];
			sdclk <= 1'b0;
		end
		if (cpu_rd) sdclk <= 1'b1;
	end
end

endmodule
