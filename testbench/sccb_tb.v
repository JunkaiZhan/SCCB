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
//      Testbench
// Dependencies: 
//      sccb.v
// Revision: 
// Revision 0.01 - File Created
//
////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module sccb_tb();

// Parameter Declarations 
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;
parameter time_cycle = 10;

// Interface Declaration
reg clk, rstn;
reg [DATA_WIDTH - 1 : 0] data_in;
reg [ADDR_WIDTH - 1 : 0] addr;     // address to wirte or read
reg write;                         // 1 - write, 0 - read
reg valid_in;

wire sda, direction;
reg sda_out;
assign sda = !direction ? sda_out : 1'bz;

wire scl;
wire [DATA_WIDTH - 1 : 0] data_out; 
wire done; 

// Design Under Test
sccb dut(
    .clk(clk),
    .rstn(rstn),
    .data_in(data_in),
    .addr(addr),
    .write(write),
    .valid_in(valid_in),
    .sda(sda),
    .scl(scl),
    .data_out(data_out),
    .done(done),
    .direction(direction)
);

// clock and reset_n
initial begin
    clk = 1;
    rstn = 1;
    #(time_cycle*2) rstn = 0;
    #(time_cycle*2) rstn = 1;
end

always begin
    #(time_cycle/2) clk = ~clk;
end

// dump out file and variables
initial begin
    $dumpfile("sccb_wv.vcd");
    $dumpvars(0, dut);
end

// logic
initial begin
    data_in = 0;
    addr = 0;
    write = 0;
    valid_in = 0;
    sda_out = 1;
    #(time_cycle*6);

    // write command
    data_in = 8'h5b;
    addr = 8'ha6;
    write = 0;
    sda_out = 0;
    valid_in = 1;
    #time_cycle;
    data_in = 8'h5b;
    addr = 8'ha6;
    write = 0;
    valid_in = 0;
    sda_out = 0;
    #(time_cycle*100);

    // write command 2
    data_in = 8'h73;
    addr = 8'h95;
    write = 0;
    valid_in = 1;
    sda_out = 0;
    #time_cycle;
    data_in = 8'h73;
    addr = 8'h95;
    write = 0;
    valid_in = 0;
    sda_out = 0;
    #(time_cycle*100);

    // read command _ failed
    data_in = 8'h5b;
    addr = 8'ha6;
    write = 1;
    valid_in = 1;
    sda_out = 1;
    #time_cycle;
    data_in = 8'h5b;
    addr = 8'ha6;
    write = 1;
    valid_in = 0;
    sda_out = 1;
    #(time_cycle*100);

    // read command _ pass
    data_in = 8'h73;
    addr = 8'h95;
    write = 1;
    valid_in = 1;
    sda_out = 0;
    #time_cycle;
    data_in = 8'h73;
    addr = 8'h95;
    write = 1;
    valid_in = 0;
    sda_out = 0;
    #(time_cycle*100);

    #(time_cycle*100);
    $finish;
end

endmodule
