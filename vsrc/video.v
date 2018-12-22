//////////////////////////////////////////////////////////////////////////////////
// Company: Private
// Engineer: JunkaiZhan
// 
// Create Date: 2018-12-20
// Design Name: Image Recognition
// Module Name: video interface driver for dcmi (for ov7725)
// Target Devices: ASIC/FPGA
// Tool Version: 
// Description: 
// 
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
//
// //////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module video(
    clk, rstn,
    vsync, href,
    pclk, xclk,
    vreset, pwdn,
    vdata,
    done, frame_data
);

// Parameter Declarations -------------------------------------------
parameter VDATA_WIDTH = 10;
parameter ROW_NUM     = 240;
parameter PIXEL_NUM   = 320;
parameter PIXEL_WIDTH = 15
parameter FRAME_WIDTH = PIXEL_NUM * ROW_NUM;

parameter STATE_WIDTH = 1;
localparam IDLE = 1'd0;
localparam VSYNC = 1'd1;

// Interface Declarations -------------------------------------------
input clk, rstn;                    // global clk and reset_n

// ov7725 camera video interface
input vsync;                        // vertical synchronization
input href;                         // horizontal synchronization
input pclk;                         // pixel clock
output xclk;                        // system clock
output vreset;                      // ov reset (active low)
output pwdn;                        // power down mode selection (active high)
input [VDATA_WIDTH - 1 : 0] vdata;  // video parallel dataß

// internal interface
output done;
output [PIXEL_WIDTH - 1 : 0] frame_data [FRAME_WIDTH - 1 : 0];

// Reg and Wire Declarations ----------------------------------------
reg [PIXEL_WIDTH - 1 : 0] frame_data_r [FRAME_WIDTH - 1 : 0];

reg state, next_state;

// Seq Logic --------------------------------------------------------
always @ (posedge clk or negedge rstn) begin
    if (!rstn) 
end

