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

module sccb_fsm(
    clk, rstn, 
    valid_in, write, data_in, addr, 
    done, data_out,
    scl, sda
);

// Parameter Declarations --------------------------------------
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;

parameter BYTE_COUNT_WIDTH = 2;
parameter BIT_COUNT_WIDTH  = 4;

`define SEQ_LENGTH   24;
`define STATE_WIDTH   5;

localparam IDLE      = `STATE_WIDTH'd0;
localparam START     = `STATE_WIDTH'd1;
localparam TRA_0     = `STATE_WIDTH'd2;
localparam TRA_1     = `STATE_WIDTH'd3;
localparam TRA_2     = `STATE_WIDTH'd4;
localparam TRA_3     = `STATE_WIDTH'd5;
localparam ACK_1     = `STATE_WIDTH'd6;
localparam ACK_2     = `STATE_WIDTH'd7;
localparam ACK_3     = `STATE_WIDTH'd8;
localparam REC_1     = `STATE_WIDTH'd9;
localparam REC_2     = `STATE_WIDTH'd10;
localparam PER_ACK_1 = `STATE_WIDTH'd11;
localparam PER_ACK_2 = `STATE_WIDTH'd12;
localparam PER_ACK_3 = `STATE_WIDTH'd13;
localparam PER_ACK_4 = `STATE_WIDTH'd14;
localparam STOP_1    = `STATE_WIDTH'd15;
localparam STOP_2    = `STATE_WIDTH'd16;
localparam STOP_3    = `STATE_WIDTH'd17;

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

// inout process
wire in_sda, out_sda, sda_out_en;
assign in_sda = !sda_out_en & sda;
assign sda = sda_out_en ? out_sda : 1'bz;

// output data process
assign done = state == STOP_3; // one pluse
assign data_out = data_receive;

// Reg and Wire Declarations -----------------------------------
reg [`STATE_WIDTH - 1 : 0] state;
reg [`STATE_WIDTH - 1 : 0] next_state;

reg [BYTE_COUNT_WIDTH - 1 : 0] byte_counter;
reg [BIT_COUNT_WIDTH - 1 : 0] bit_counter;
reg [`SEQ_LENGTH - 1 : 0] seq;

reg ack_valid;
reg [DATA_WIDTH - 1 : 0] data_receive;
reg [2:0] rec_counter;

wire rec_finish;
assign rec_finish = &rec_counter;

wire valid_bit;
assign valid_bit = seq[`SEQ_LENGTH - 1];

wire byte_counter_is_zero;
wire bit_counter_is_zero;
assign byte_counter_is_zero = ~|byte_counter;
assign bit_counter_is_zero  = ~|bit_counter;

wire read_command;
wire write_command;
assign write_command = valid_in && !write;
assign read_command = valid_in && write;

// Seq Logic ---------------------------------------------------
always @ (posedge clk or negedge rstn) begin
    if(!rstn) state <= IDLE;
    else state <= next_state;
end

always @ (*) begin
    case(state)
    IDLE: begin 
        if(valid_in) next_state = START;
        else next_state = IDLE;
    end
    START: begin next_state = TRA_0; end
    TRA_0: begin next_state = TRA_1; end
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
            2: begin next_state = TRA_0; end
            1: begin
                if(read_command) next_state = START;
                else if(write_command) next_state = TRA_0;
            end 
            0: begin
                if(read_command) next_state = REC_1;
                else if(write_command) next_state = STOP_1;
            end
            default: next_state = TRA_0;
            endcase
        end else begin 
            next_state = STOP_1;
        end
    end
    REC_1: begin next_state = REC_2; end
    REC_2: begin 
        if(rec_finish) next_state = PER_ACK_1;
        else next_state = REC_1; 
    end
    PER_ACK_1: begin next_state = PER_ACK_2; end
    PER_ACK_2: begin next_state = PER_ACK_3; end
    PER_ACK_3: begin next_state = PER_ACK_4; end
    PER_ACK_4: begin next_state = STOP_1;    end
    STOP_1:    begin next_state = STOP_2;    end
    STOP_2:    begin next_state = STOP_3;    end
    STOP_3:    begin next_state = IDLE;      end
    endcase
end

always @ (*) begin
    case(state)
    IDLE:      begin scl = 1; sda_out_en = 1; out_sda = 1; end
    START:     begin scl = 1; sda_out_en = 1; out_sda = 0; end
    TRA_0:     begin scl = 0; sda_out_en = 1; end
    TRA_1:     begin scl = 0; sda_out_en = 1; out_sda = valid_bit; end
    TRA_2:     begin scl = 1; sda_out_en = 1; out_sda = valid_bit; end
    TRA_3:     begin scl = 0; sda_out_en = 1; out_sda = valid_bit; end
    ACK_1:     begin scl = 0; sda_out_en = 0; end
    ACK_2:     begin scl = 1; sda_out_en = 0; end
    ACK_3:     begin scl = 0; sda_out_en = 0; end
    REC_1:     begin scl = 0; sda_out_en = 0; end
    REC_2:     begin scl = 1; sda_out_en = 0; end
    PER_ACK_1: begin scl = 0; sda_out_en = 1; end
    PER_ACK_2: begin scl = 0; sda_out_en = 1; out_sda = 0; end
    PER_ACK_3: begin scl = 1; sda_out_en = 1; out_sda = 0; end
    PER_ACK_4: begin scl = 0; sda_out_en = 1; out_sda = 0; end
    STOP_1:    begin scl = 0; sda_out_en = 1; out_sda = 0; end
    STOP_2:    begin scl = 1; sda_out_en = 1; out_sda = 0; end
    STOP_3:    begin scl = 1; sda_out_en = 1; out_sda = 1; end
    default:   begin scl = 1; sda_out_en = 1; out_sda = 1; end
    endcase
end

// counter driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        byte_counter <= 0;
        bit_counter  <= 0;
    end else begin
        if(state == TRA_0) begin
            if(!bit_counter_is_zero) begin 
                bit_counter <= bit_counter - 1'b1; 
            end else if(!byte_counter_is_zero) begin 
                bit_counter <= 8; 
                byte_counter <= byte_counter - 1'b1; 
            end
        end else if(valid_in) begin 
            byte_counter <= 3;
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
        end else if(state == TRA_0) begin
            seq <= seq << 1;
        end else begin
            seq <= 'd0;
        end
    end
end

// ack_valid driver
always @ (posedge clk or negedge rstn) begin
    if(!rstn) begin
        ack_valid <= 1'b0;
    end else begin
        if(state == ACK_1) ack_valid <= !in_sda;
        else ack_valid <= 1'b0;
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

endmodule
