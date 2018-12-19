//////////////////////////////////////////////////////////////////////////////////
// Company: Private
// Engineer: JunkaiZhan
// 
// Create Date: 2018-12-16
// Design Name: Image Recognition
// Module Name: dcmi (for ov7725)
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

module dcmi(clk, rstn, );

// Parameter Declarations -------------------------------------

// Interface Declarations -------------------------------------
input clk;
input rstn;

// ov7725 interface
output sioc;         // SCCB serial interface clock
output siod;         // SCCB serial interface data
input vsync;         // vertical synchronization
input href;          // horizontal synchronization (optional)
input pclk;          // pixel clock
output xclk;         // system clock≥
output [9:0] vdata;  // parallel data
output vreset;       // ov reset (active low)
output pwdn;         // power down mode selection (active high)

// internal interface

// Reg and Wire Declarations ----------------------------------

// Sub Module Declarations ------------------------------------

// Comb Logic -------------------------------------------------

// Seq Logic --------------------------------------------------