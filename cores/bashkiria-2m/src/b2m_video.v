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
// Design File: b2m_video.v
//
// Video subsystem design file of Bashkiria-2M replica.

module b2m_video(
	input clk50,
	output reg hr,
	output reg vr,
	output reg vid_irq,
	output reg[3:0] r,
	output reg[3:0] g,
	output reg[3:0] b,
	output reg drq,
	output reg[13:0] addr,
	input[15:0] idata,
	input[1:0] pal_idx,
	input[7:0] pal_data,
	input pal_we_n,
	input color_mode,
	input mode);

reg[7:0] palette[0:3];
reg[7:0] pclr;
reg vout;

always @(*)
	casex ({vout,color_mode})
	2'b0x: {r,g,b} = {4'b0000,4'b0000,4'b0000};
	2'b10: {r,g,b} = {{2{pclr[1:0]}},{2{pclr[1:0]}},{2{pclr[1:0]}}};
	2'b11: {r,g,b} = {{2{pclr[3:2]}},{2{pclr[5:4]}},{2{pclr[7:6]}}};
	endcase

// mode select

always @(*) begin
		pclr = ~palette[{data0[8],data0[0]}];
		hr = h_cnt0 >= 10'd420 && h_cnt0 < 10'd480 ? 1'b0 : 1'b1;
		vr = v_cnt0 >= 10'd565 && v_cnt0 < 10'd571 ? 1'b0 : 1'b1;
		vout = h_cnt0 >= 10'd5 && h_cnt0 < 10'd389 && v_cnt0 < 10'd512;
		addr = {h_cnt0[8:3], v_cnt0[8:1]};
		drq = h_cnt0[8:7] < 2'b11 && v_cnt0[9]==0 && h_cnt0[2]==0 && state!=0;
		vid_irq = ~v_cnt0[9];
	end

// mode 0, 800x600@50Hz

reg[1:0] state;
reg[9:0] h_cnt0;
reg[9:0] v_cnt0;
reg[15:0] data0;

reg[9:0] h_cnt1;
reg[9:0] v_cnt1;
reg[15:0] data1;
reg[13:0] addr1;
reg drq1;
reg irq1;

always @(posedge clk50)
begin
	casex (state)
	2'b00: state <= 2'b01;
	2'b01: state <= 2'b10;
	2'b1x: state <= 2'b00;
	endcase
	if (state==2'b00) begin
		if (h_cnt0[2:0]==3'b100 && h_cnt0[8:3]<6'h30) data0 <= idata; else data0 <= {1'b0,data0[15:1]};
		if (h_cnt0+1'b1 == 10'd532) begin
			h_cnt0 <= 0;
			if (v_cnt0+1'b1 == 10'd624 )
				v_cnt0 <= 0;
			else
				v_cnt0 <= v_cnt0+1'b1;
		end else
			h_cnt0 <= h_cnt0+1'b1;
	end
	if (!pal_we_n) palette[pal_idx] <= pal_data;
	addr1 <= {h_cnt1[8:3], v_cnt1[8:1]};
	drq1 <= h_cnt1[8:7] < 2'b11 && v_cnt1[9]==0 && h_cnt1[2]==0;
	irq1 <= ~v_cnt1[9];
end

endmodule
