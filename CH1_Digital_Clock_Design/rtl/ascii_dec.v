`timescale 1ns / 1ps
module ascii_dec #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input reset,
    input [DATA_WIDTH - 1 : 0] rx_data,
    input rx_done,
    output [8:0] dec_out
);
    // wire
    wire [8:0] w_dec_result;

    // ascii_lut instantiation
    ascii_lut #(
        .DATA_WIDTH(DATA_WIDTH)
    ) U_ASCII_LUT (
        .rx_data(rx_data),
        .dec_result(w_dec_result)
    );

    // ascii_fsm instantiation
    ascii_fsm #(
        .DATA_WIDTH(DATA_WIDTH)
    ) U_ASCII_FSM (
        .clk(clk),
        .reset(reset),
        .rx_done(rx_done),
        .dec_result(w_dec_result),
        .dec_out(dec_out)
    );


endmodule

//////////

module ascii_lut #(
    parameter DATA_WIDTH = 8
) (
    input [DATA_WIDTH - 1 : 0] rx_data,
    output reg [8:0] dec_result
);
    // ASCII parameter
    localparam r = 8'h72;
    localparam s = 8'h73;
    localparam c = 8'h63;
    localparam m = 8'h6D;
    localparam l = 8'h6C;
    localparam L = 8'h4C;
    localparam R = 8'h52;
    localparam U = 8'h55;
    localparam D = 8'h44;

    // decoding result parameter
    localparam RUN = 9'b100000000;
    localparam STOP = 9'b010000000;
    localparam CLEAR = 9'b001000000;
    localparam MODE = 9'b000100000;
    localparam LAP = 9'b000010000;
    localparam LEFT = 9'b000001000;
    localparam RIGHT = 9'b000000100;
    localparam UP = 9'b000000010;
    localparam DOWN = 9'b000000001;

    always @(*) begin
        case (rx_data)
            r: dec_result = RUN;
            s: dec_result = STOP;
            c: dec_result = CLEAR;
            m: dec_result = MODE;
            l: dec_result = LAP;
            L: dec_result = LEFT;
            R: dec_result = RIGHT;
            U: dec_result = UP;
            D: dec_result = DOWN;
            default : dec_result = 9'b000000000;
        endcase

    end
endmodule

////////// 

module ascii_fsm #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input reset,
    input rx_done,
    input [8:0] dec_result,
    output [8:0] dec_out
);
    // state parameter
    parameter IDLE = 1'b0, TICK = 1'b1;

    // register
    reg n_state, c_state;
    reg [8:0] dec_out_next, dec_out_reg;

    // assignment
    assign dec_out = dec_out_reg;

    // CL
    always @(*) begin
        n_state = c_state;
        dec_out_next = dec_out_reg;
        case (c_state)
            IDLE: begin
                dec_out_next = 0;
                if (rx_done) begin
                    n_state = TICK;
                end
            end
            TICK: begin
                dec_out_next = dec_result;
                n_state = IDLE;
            end
        endcase
    end

    // SL
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            dec_out_reg <= 0;
        end else begin
            c_state <= n_state;
            dec_out_reg <= dec_out_next;
        end
    end

endmodule
