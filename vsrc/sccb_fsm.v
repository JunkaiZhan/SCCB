//////////////////////////////////////////////////////////////////////////////////
// Company: Private
// Engineer: JunkaiZhan
// 
// Create Date: 2018-12-17
// Design Name: Image Recognition
// Module Name: sccb fsm for sccb interface driver for dcmi (for ov7725)
// Target Devices: ASIC/FPGA
// Tool Version: 
// Description: 
//      Like IIC interface
// Dependencies: 
// 
// Revision: 
// Revision 0.01 - File Created
//
// //////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`define SEQ_LENGTH   24;
`define STATE_WIDTH  5;

module sccb_fsm(
    clk, rstn, 
    valid_in, write, 
    data_in, addr, 
    done, data_out,
    scl, sda,
    direction // for debug
);

// Parameter Declarations --------------------------------------
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;

parameter BYTE_COUNT_WIDTH = 2;
parameter BIT_COUNT_WIDTH  = 4;

localparam IDLE      = 5'h0;
localparam START_1   = 5'd1;
localparam START_2   = 5'd2;
localparam TRA_1     = 5'd3;
localparam TRA_2     = 5'd4;
localparam TRA_3     = 5'd5;
localparam ACK_1     = 5'd6;
localparam ACK_2     = 5'd7;
localparam ACK_3     = 5'd8;
localparam REC_1     = 5'd9;
localparam REC_2     = 5'd10;
localparam REC_3     = 5'd11;
localparam PER_ACK_1 = 5'd12;
localparam PER_ACK_2 = 5'd13;
localparam PER_ACK_3 = 5'd14;
localparam STOP_1    = 5'd15;
localparam STOP_2    = 5'd16;
localparam STOP_3    = 5'd17;
localparam START_00  = 5'd18; // restart
localparam START_01  = 5'd19;
localparam START_02  = 5'd20;
localparam START_03  = 5'd21;

localparam DEVICE_ADDRESS = 7'h42;

// Interface Declarations --------------------------------------
input clk, rstn;
input valid_in, write;
input [DATA_WIDTH - 1 : 0] data_in;
input [ADDR_WIDTH - 1 : 0] addr;
output [DATA_WIDTH - 1 : 0] data_out;
output done;

output scl;
inout  sda;

output direction; // for debug

// inout process
wire in_sda;
reg out_sda, sda_out_en;
assign in_sda = !sda_out_en & sda;
assign sda = sda_out_en ? out_sda : 1'bz;

reg scl_r;
assign scl = scl_r;

assign direction = sda_out_en; // for debug

// Reg and Wire Declarations -----------------------------------
reg [5 - 1 : 0] state;
reg [5 - 1 : 0] next_state;

reg [BYTE_COUNT_WIDTH - 1 : 0] byte_counter;
reg [BIT_COUNT_WIDTH - 1 : 0] bit_counter;
reg [24 - 1 : 0] seq;

reg ack_valid;
reg [DATA_WIDTH - 1 : 0] data_receive;
reg [3:0] rec_counter;

// output data process
assign done = state == STOP_3; // one pluse
assign data_out = data_receive;

wire rec_finish;
assign rec_finish = rec_counter == 4'd8;

wire valid_bit;
assign valid_bit = seq[24 - 1];

wire byte_counter_is_zero;
wire bit_counter_is_zero;
assign byte_counter_is_zero = ~|byte_counter;
assign bit_counter_is_zero  = ~|bit_counter;

reg read_command;
reg write_command;

// Seq Logic ---------------------------------------------------
always @ (posedge clk or negedge rstn) begin
    if(!rstn) state <= IDLE;
    else state <= next_state;
end

always @ (*) begin
    case(state)
    IDLE: begin 
        if(read_command || write_command) next_state = START_1;
        else next_state = IDLE;
    end
    START_00: begin next_state = START_01; end
    START_01: begin next_state = START_02; end
    START_02: begin next_state = START_03; end
    START_03: begin next_state = START_1; end
    START_1: begin next_state = START_2; end
    START_2: begin next_state = TRA_1; end
    TRA_1: begin next_state = TRA_2; end
    TRA_2: begin next_state = TRA_3; end
    TRA_3: begin 
        if(bit_counter_is_zero) next_state = ACK_1;
        else next_state = TRA_1;
    end
    ACK_1: begin next_state = ACK_2; end
    ACK_2: begin next_state = ACK_3; end
    ACK_3: begin
        if(ack_valid) begin
            case(byte_counter)
            2: begin next_state = TRA_1; end
            1: begin
                if(read_command) next_state = START_00;
                else if(write_command) next_state = TRA_1;
            end 
            0: begin
                if(read_command) next_state = REC_1;
                else if(write_command) next_state = STOP_1;
            end
            default: next_state = TRA_1;
            endcase
        end else begin 
            next_state = STOP_1;
        end
    end
    REC_1: begin next_state = REC_2; end
    REC_2: begin next_state = REC_3; end
    REC_3: begin 
        if(rec_finish) next_state = PER_ACK_1;
        else next_state = REC_1; 
    end
    PER_ACK_1: begin next_state = PER_ACK_2; end
    PER_ACK_2: begin next_state = PER_ACK_3; end
    PER_ACK_3: begin next_state = STOP_1;    end
    STOP_1:    begin next_state = STOP_2;    end
    STOP_2:    begin next_state = STOP_3;    end
    STOP_3:    begin next_state = IDLE;      end
    endcase
end

always @ (*) begin
    case(state)
    IDLE:      begin scl_r = 1; sda_out_en = 1; out_sda = 1; end
    START_00:  begin scl_r = 0; sda_out_en = 1; out_sda = 0; end
    START_01:  begin scl_r = 1; sda_out_en = 1; out_sda = 0; end
    START_02:  begin scl_r = 1; sda_out_en = 1; out_sda = 1; end
    START_03:  begin scl_r = 1; sda_out_en = 1; out_sda = 1; end
    START_1:   begin scl_r = 1; sda_out_en = 1; out_sda = 0; end
    START_2:   begin scl_r = 0; sda_out_en = 1; out_sda = 0; end
    TRA_1:     begin scl_r = 0; sda_out_en = 1; out_sda = valid_bit; end
    TRA_2:     begin scl_r = 1; sda_out_en = 1; out_sda = valid_bit; end
    TRA_3:     begin scl_r = 0; sda_out_en = 1; out_sda = valid_bit; end
    ACK_1:     begin scl_r = 0; sda_out_en = 0; end
    ACK_2:     begin scl_r = 1; sda_out_en = 0; end
    ACK_3:     begin scl_r = 0; sda_out_en = 0; end
    REC_1:     begin scl_r = 0; sda_out_en = 0; end
    REC_2:     begin scl_r = 1; sda_out_en = 0; end
    REC_3:     begin scl_r = 0; sda_out_en = 0; end
    PER_ACK_1: begin scl_r = 0; sda_out_en = 1; out_sda = 0; end
    PER_ACK_2: begin scl_r = 1; sda_out_en = 1; out_sda = 0; end
    PER_ACK_3: begin scl_r = 0; sda_out_en = 1; out_sda = 0; end
    STOP_1:    begin scl_r = 0; sda_out_en = 1; out_sda = 0; end
    STOP_2:    begin scl_r = 1; sda_out_en = 1; out_sda = 0; end
    STOP_3:    begin scl_r = 1; sda_out_en = 1; out_sda = 1; end
    default:   begin scl_r = 1; sda_out_en = 1; out_sda = 1; end
    endcase
end

// counter driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        byte_counter <= 0;
        bit_counter  <= 0;
    end else begin
        if(state == TRA_1) begin
            if(!bit_counter_is_zero) begin 
                bit_counter <= bit_counter - 1'b1; 
            end else if(!byte_counter_is_zero) begin 
                bit_counter <= 7; 
                byte_counter <= byte_counter - 1'b1; 
            end
        end else if(valid_in) begin 
            byte_counter <= 2;
            bit_counter  <= 8;
        end
    end
end

// address + data driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        seq <= 'd0;
    end else begin
        if(state == IDLE && write_command) begin
            seq <= {DEVICE_ADDRESS, 1'b0, addr, data_in};
        end else if(state == IDLE && read_command) begin
            seq <= {DEVICE_ADDRESS, 1'b0, addr, DEVICE_ADDRESS, 1'b1};
        end else if(state == TRA_3) begin
            seq <= seq << 1;
        end
    end
end

// ack_valid driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        ack_valid <= 1'b0;
    end else begin
        if(state == ACK_1) ack_valid <= !in_sda;
    end
end

// data receive driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        data_receive <= 'b0;
        rec_counter <= 'b0;
    end else begin
        if(state == REC_1) begin
            data_receive <= {data_receive[DATA_WIDTH - 2 : 0], in_sda};
            rec_counter <= rec_counter + 1'b1;
        end else if(done) begin
            rec_counter <= 'b0;
        end
    end
end

// read_command and write_command driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        read_command <= 1'b0;
        write_command <= 1'b0;
    end else begin
        if(valid_in) begin
            write_command <= !write;
            read_command <= write;
        end else if(done) begin
            write_command <= 1'b0;
            read_command <= 1'b0;
        end
    end
end

endmodule
