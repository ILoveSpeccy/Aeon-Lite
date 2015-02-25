// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: radio86rk.v
//
// Top level design file.
// -------------------------------------------------------------------- 
// Ported to "Aeon Lite" by Dmitriy Schapotschkin aka ILoveSpeccy
// http://www.speccyland.net '2015

module radio86rk(
   input			clk50,

   inout    [15:0]   SRAM_DQ,    // SRAM Data bus 16 Bits
   output   [17:0]   SRAM_ADDR,  // SRAM Address bus 18 Bits
   output            SRAM_UB_N,  // SRAM High-byte Data Mask 
   output            SRAM_LB_N,  // SRAM Low-byte Data Mask 
   output            SRAM_WE_N,  // SRAM Write Enable
   output            SRAM_CE_N,  // SRAM Chip Enable
   output            SRAM_OE_N,  // SRAM Output Enable

   output            SOUND_L,
   output            SOUND_R,
   
   output            VGA_HS,
   output            VGA_VS,
   output   [3:0]    VGA_R,
   output   [3:0]    VGA_G,
   output   [3:0]    VGA_B,

   input             PS2_CLK,
   input             PS2_DAT,

   input             SD_DAT,     // SD Card Data            (MISO)
   output            SD_DAT3,    // SD Card Data 3          (CSn)
   output            SD_CMD,     // SD Card Command Signal  (MOSI)
   output            SD_CLK      // SD Card Clock           (SCK)
);

reg startup;
reg tapein = 1'b0;
wire hdla;
wire cpurst;
wire videomode;

wire[7:0] ppa1_o;
wire[7:0] ppa1_a;
wire[7:0] ppa1_b;
wire[7:0] ppa1_c;

////////////////////   RESET   ////////////////////
reg[3:0] reset_cnt;
reg reset_n;
wire reset = ~reset_n;

always @(posedge clk50) begin
// if (KEY[0] && reset_cnt==4'd14)
   if (!cpurst && reset_cnt==4'd14)
      reset_n <= 1'b1;
   else begin
      reset_n <= 1'b0;
      reset_cnt <= reset_cnt+4'd1;
   end
end

////////////////////   MEM   ////////////////////
wire sram_msb = 0;
wire[7:0] mem_o = sram_msb ? SRAM_DQ[15:8] : SRAM_DQ[7:0];
wire[7:0] rom_o;

assign SRAM_DQ[7:0]  = SRAM_WE_N| sram_msb ? 8'bZZZZZZZZ : cpu_o;
assign SRAM_DQ[15:8] = 8'bZZZZZZZZ; // SRAM_WE_N|~sram_msb ? 8'bZZZZZZZZ : cpu_o;
assign SRAM_ADDR = vid_rd ? {3'b000,vid_addr[14:0]} : {3'b000,addrbus[14:0]};
assign SRAM_UB_N = vid_rd ? 1'b0 : ~sram_msb;
assign SRAM_LB_N = vid_rd ? 1'b0 : sram_msb;
assign SRAM_WE_N = vid_rd ? 1'b1 : cpu_wr_n|addrbus[15]|hlda;
assign SRAM_OE_N = ~(vid_rd|cpu_rd);
assign SRAM_CE_N = 0;

biossd rom(.clka(clk50), .addra({addrbus[11]|startup,addrbus[10:0]}), .douta(rom_o));

////////////////////   CPU   ////////////////////
wire[15:0] addrbus;
wire[7:0] cpu_o;
wire cpu_sync;
wire cpu_rd;
wire cpu_wr_n;
wire cpu_int;
wire cpu_inta_n;
wire inte;
reg[7:0] cpu_i;

always @(*)
   casex (addrbus[15:13])
      3'b0xx: cpu_i = startup ? rom_o : mem_o;
      3'b100: cpu_i = ppa1_o;
      3'b101: cpu_i = sd_o;
      3'b110: cpu_i = crt_o;
      3'b111: cpu_i = rom_o;
   endcase

wire ppa1_we_n = addrbus[15:13]!=3'b100|cpu_wr_n;
wire ppa2_we_n = addrbus[15:13]!=3'b101|cpu_wr_n;
wire crt_we_n  = addrbus[15:13]!=3'b110|cpu_wr_n;
wire crt_rd_n  = addrbus[15:13]!=3'b110|~cpu_rd;
wire dma_we_n  = addrbus[15:13]!=3'b111|cpu_wr_n;

reg cpu_flag;
reg[10:0] cpu_cnt;

wire cpu_ce = cpu_ce2;
wire cpu_ce2 = cpu_flag^cpu_cnt[10];

always @(posedge clk50) begin
   cpu_cnt <= cpu_cnt + 11'd41;
   cpu_flag <= cpu_flag^cpu_ce2;
   startup <= reset|(startup&~addrbus[15]);
end

k580wm80a CPU(.clk(clk50), .ce(cpu_ce & hlda==0), .reset(reset),
   .idata(cpu_i), .addr(addrbus), .sync(cpu_sync), .rd(cpu_rd), .wr_n(cpu_wr_n),
   .intr(cpu_int), .inta_n(cpu_inta_n), .odata(cpu_o), .inte_o(inte));

////////////////////   VIDEO   ////////////////////
wire[7:0] crt_o;
wire[3:0] vid_line;
wire[6:0] vid_char;
wire[15:0] vid_addr;
wire[3:0] dma_dack;
wire[7:0] dma_o;
wire[1:0] vid_lattr;
wire[1:0] vid_gattr;
wire vid_cce,vid_drq,vid_irq;
wire vid_lten,vid_vsp,vid_rvv,vid_hilight;
wire dma_owe_n,dma_ord_n,dma_oiowe_n,dma_oiord_n;

wire vid_rd = ~dma_oiord_n;

k580wt57 dma(.clk(clk50), .ce(vid_cce), .reset(reset),
   .iaddr(addrbus[3:0]), .idata(cpu_o), .drq({1'b0,vid_drq,2'b00}), .iwe_n(dma_we_n), .ird_n(1'b1),
   .hlda(hlda), .hrq(hlda), .dack(dma_dack), .odata(dma_o), .oaddr(vid_addr),
   .owe_n(dma_owe_n), .ord_n(dma_ord_n), .oiowe_n(dma_oiowe_n), .oiord_n(dma_oiord_n) );

k580wg75 crt(.clk(clk50), .ce(vid_cce),
   .iaddr(addrbus[0]), .idata(cpu_o), .iwe_n(crt_we_n), .ird_n(crt_rd_n),
   .vrtc(VGA_VS), .hrtc(VGA_HS), .dack(dma_dack[2]), .ichar(mem_o), .drq(vid_drq), .irq(vid_irq),
   .odata(crt_o), .line(vid_line), .ochar(vid_char), .lten(vid_lten), .vsp(vid_vsp),
   .rvv(vid_rvv), .hilight(vid_hilight), .lattr(vid_lattr), .gattr(vid_gattr) );

rk_video vid(.clk50mhz(clk50), .hr(VGA_HS), .vr(VGA_VS), .cce(vid_cce),
   .r(VGA_R), .g(VGA_G), .b(VGA_B), .line(vid_line), .ichar(vid_char),
   .vsp(vid_vsp), .lten(vid_lten), .rvv(vid_rvv), .videomode(videomode) );

////////////////////   KBD   ////////////////////
wire[7:0] kbd_o;
wire[2:0] kbd_shift;

rk_kbd kbd(.clk(clk50), .reset(reset), .ps2_clk(PS2_CLK), .ps2_dat(PS2_DAT),
   .addr(~ppa1_a), .odata(kbd_o), .cpurst(cpurst), .videomode(videomode), .shift(kbd_shift));

////////////////////   SYS PPA   ////////////////////
k580ww55 ppa1(.clk(clk50), .reset(reset), .addr(addrbus[1:0]), .we_n(ppa1_we_n),
   .idata(cpu_o), .odata(ppa1_o), .ipa(ppa1_a), .opa(ppa1_a),
   .ipb(~kbd_o), .opb(ppa1_b), .ipc({~kbd_shift,tapein,ppa1_c[3:0]}), .opc(ppa1_c));

////////////////////   SOUND   ////////////////////
assign SOUND_L = ppa1_c[0]^inte;
assign SOUND_R = ppa1_c[0]^inte;

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
      if (addrbus[0]==1'b0 && ~ppa2_we_n) sdcs <= cpu_o[0];
      if (addrbus[0]==1'b1 && ~ppa2_we_n) begin
         if (sdclk) sddata <= {sddata[5:0],SD_DAT};
         sdcmd <= cpu_o[7];
         sdclk <= 1'b0;
      end
      if (cpu_rd) sdclk <= 1'b1;
   end
end

endmodule
