`timescale 1ns / 1ps
module ascii_dec #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input reset,
    input [DATA_WIDTH - 1 : 0] rx_data,
    input rx_done,
    output [14:0] dec_out
);
    // wire
    wire [14:0] w_dec_result;

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
    output reg [14:0] dec_result
);
    // ASCII parameter for fnd
    localparam r = 8'h72;
    localparam s = 8'h73;
    localparam c = 8'h63;
    localparam m = 8'h6D;
    localparam l = 8'h6C;
    localparam L = 8'h4C;
    localparam R = 8'h52;
    localparam U = 8'h55;
    localparam D = 8'h44;

    // ASCII parameter for sender
    localparam _1 = 8'h31;
    localparam _2 = 8'h32;
    localparam _3 = 8'h33;
    localparam _4 = 8'h34;
    localparam _5 = 8'h35;
    localparam _6 = 8'h36;


    // decoding result parameter -> 
    // [14:9] for sender, [8:4] for stopwatch, [3:0] for watch,
    localparam RUN = 15'b000000_100000000;
    localparam STOP = 15'b000000_010000000;
    localparam CLEAR = 15'b000000_001000000;
    localparam MODE = 15'b000000_000100000;
    localparam LAP = 15'b000000_000010000;
    localparam LEFT = 15'b000000_000001000;
    localparam RIGHT = 15'b000000_000000100;
    localparam UP = 15'b000000_000000010;
    localparam DOWN = 15'b000000_000000001;
    localparam ONE = 15'b100000_000000000;
    localparam TWO = 15'b010000_000000000;
    localparam THREE = 15'b001000_000000000;
    localparam FOUR = 15'b000100_000000000;
    localparam FIVE = 15'b000010_000000000;
    localparam SIX = 15'b000001_000000000;

    always @(*) begin
        dec_result = 15'b000000_000000000;
        case (rx_data)
            r:  dec_result = RUN;
            s:  dec_result = STOP;
            c:  dec_result = CLEAR;
            m:  dec_result = MODE;
            l:  dec_result = LAP;
            L:  dec_result = LEFT;
            R:  dec_result = RIGHT;
            U:  dec_result = UP;
            D:  dec_result = DOWN;
            _1: dec_result = ONE;
            _2: dec_result = TWO;
            _3: dec_result = THREE;
            _4: dec_result = FOUR;
            _5: dec_result = FIVE;
            _6: dec_result = SIX;
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
    input [14:0] dec_result,
    output [14:0] dec_out
);
    // state parameter
    localparam IDLE = 1'b0, TICK = 1'b1;

    // register
    reg n_state, c_state;
    reg [14:0] dec_out_next, dec_out_reg;

    // assignment
    assign dec_out = dec_out_reg;

    // CL
    always @(*) begin
        n_state = c_state;
        dec_out_next = dec_out_reg;
        case (c_state)
            IDLE: begin
                if (rx_done) begin
                    n_state = TICK;
                    dec_out_next = dec_result;
                end
            end
            TICK: begin
                dec_out_next = 0;
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
