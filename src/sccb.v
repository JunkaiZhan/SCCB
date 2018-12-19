//////////////////////////////////////////////////////////////////////////////////
// Company: Private
// Engineer: JunkaiZhan
// 
// Create Date: 2018-12-17
// Design Name: Image Recognition
// Module Name: sccb interface driver for dcmi (for ov7725)
// Target Devices: ASIC/FPGA
// Tool Version: 
// Description: 
//      Like IIC interface, the internal interface is like AHB
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
//
// //////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module sccb (
    clk, rstn, 
    scl, sda, 
    data_in, data_out, 
    addr, write, 
    valid_in, done
);

// Parameter Declarations -------------------------------------
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;

// Interface Declarations -------------------------------------
input clk;
input rstn;

// sccb interface
output scl;
inout  sda;

// internal interface
input  [DATA_WIDTH - 1 : 0] data_in;
input  [ADDR_WIDTH - 1 : 0] addr;     // address to wirte or read
input  write;                         // 1 - write, 0 - read
input  valid_in;
output [DATA_WIDTH - 1 : 0] data_out; 
output done;

// Reg and Wire Declarations ----------------------------------
// capture registers
reg [DATA_WIDTH - 1 : 0] data_in_r;
reg [ADDR_WIDTH - 1 : 0] addr_r;
reg write_r;

// handshake signals
reg ready;

// Seq Logic --------------------------------------------------
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_in_r <= 'b0;
        addr_r <= 'b0;
        write_r <= 'b0;
    end else begin
        if(valid_in == 1'b1 && ready == 1'b1) begin
            data_in_r <= data_in;
            addr_r <= addr;
            write_r <= write;
        end 
    end
end

always @ (posedge clk or negedge rstn) begin
    if(!rstn) ready <= 1'b1; 
    else begin
        if(valid_in == 1'b1) ready <= 1'b0;
        else if(done == 1'b1) ready <= 1'b1;
    end
end

// Sub Module Declarations ------------------------------------
sccb_fsm sccb_fsm(
    .clk(clk),
    .rstn(rstn),
    .valid_in(valid_in),
    .write(write_r),
    .data_in(data_in_r),
    .addr(addr_r),
    .done(done),
    .data_out(data_out),
    .scl(scl),
    .sda(sda)
);

endmodule


