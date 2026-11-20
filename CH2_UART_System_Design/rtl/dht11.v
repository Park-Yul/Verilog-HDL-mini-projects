`timescale 1ns / 1ps
module dht11_controller (
    input         i_clk,
    input         i_reset,
    input         i_start,
    output [39:0] o_data,
    output        o_done,
    output        o_valid,
    inout         dht11_io
);
    // wire

    wire w_tick_10us;
    wire w_pos_edge;
    wire w_neg_edge;
    wire w_dht11_io;
    wire w_dht11_io_control;

    // CL
    assign dht11_io = (w_dht11_io_control) ? w_dht11_io : 1'bz;

    // tick_10us instantiation

    tick_10us U_TICK_US (
        .i_clk  (i_clk),
        .i_reset(i_reset),
        .o_tick (w_tick_10us)
    );

    // edge_detector instantiation
    edge_detector U_edge_detector (
        .i_clk     (i_clk),
        .i_reset   (i_reset),
        .i_dht11_io(dht11_io),
        .o_pos_edge(w_pos_edge),
        .o_neg_edge(w_neg_edge)
    );

    // fsm_dht11 instantiation
    fsm_dht11 U_FSM_DHT11 (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_start(i_start),
        .i_tick_10us(w_tick_10us),
        .i_pos_edge(w_pos_edge),
        .i_neg_edge(w_neg_edge),
        .o_data(o_data),
        .o_dht11_io(w_dht11_io),
        .o_dht11_io_control(w_dht11_io_control),
        .o_done(o_done),
        .o_valid(o_valid)
    );


endmodule

//////////

module fsm_dht11 (
    input         i_clk,
    input         i_reset,
    input         i_start,
    input         i_tick_10us,
    input         i_pos_edge,
    input         i_neg_edge,
    output [39:0] o_data,
    output        o_dht11_io,
    output        o_dht11_io_control,
    output        o_done,
    output        o_valid
);

    // state parameter
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter WAIT = 3'b010;
    parameter RESPONSE_LOW = 3'b011;
    parameter RESPONSE_HIGH = 3'b100;
    parameter DATA_LOW = 3'b101;
    parameter DATA_HIGH = 3'b110;
    parameter END = 3'b111;

    // register
    reg [2:0] n_state, c_state;
    reg [10:0] tick_count_next, tick_count_reg;
    reg [5:0] bit_count_next, bit_count_reg;
    reg [39:0] data_next, data_reg;
    reg dht11_io_next, dht11_io_reg;
    reg dht11_io_control_next, dht11_io_control_reg;
    reg done_next, done_reg;
    reg valid_next, valid_reg;

    // assignment
    assign o_data = data_reg;
    assign o_dht11_io = dht11_io_reg;
    assign o_dht11_io_control = dht11_io_control_reg;
    assign o_done = done_reg;
    assign o_valid = valid_reg;

    // CL
    always @(*) begin
        n_state               = c_state;
        tick_count_next       = tick_count_reg;
        bit_count_next        = bit_count_reg;
        data_next             = data_reg;
        dht11_io_next         = dht11_io_reg;
        dht11_io_control_next = dht11_io_control_reg;
        done_next             = done_reg;
        valid_next            = valid_reg;
        case (c_state)
            IDLE: begin
                done_next = 0;
                dht11_io_next = 1;
                if (i_start) begin
                    n_state = START;
                    dht11_io_next = 0;
                    valid_next = 0;
                end
            end

            START: begin
                if (i_tick_10us) begin
                    if (tick_count_reg >= 1900 - 1) begin
                        n_state = WAIT;
                        tick_count_next = 0;
                        dht11_io_control_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            WAIT: begin
                if (i_neg_edge) begin
                    n_state = RESPONSE_LOW;
                end
            end

            RESPONSE_LOW: begin
                if (i_pos_edge) begin
                    n_state = RESPONSE_HIGH;
                end
            end

            RESPONSE_HIGH: begin
                if (i_neg_edge) begin
                    n_state = DATA_LOW;
                end
            end

            DATA_LOW: begin
                if (i_pos_edge) begin
                    n_state = DATA_HIGH;
                end
            end

            DATA_HIGH: begin
                if (i_neg_edge) begin
                    if (tick_count_reg < 5) begin
                        if (bit_count_reg >= 39) begin
                            n_state = END;
                            tick_count_next = 0;
                            bit_count_next = 0;
                            data_next = {data_reg[38:0], 1'b0};
                        end else begin
                            n_state = DATA_LOW;
                            tick_count_next = 0;
                            bit_count_next = bit_count_reg + 1;
                            data_next = {data_reg[38:0], 1'b0};

                        end
                    end else begin
                        if (bit_count_reg >= 39) begin
                            n_state = END;
                            tick_count_next = 0;
                            bit_count_next = 0;
                            data_next = {data_reg[38:0], 1'b1};
                        end else begin
                            n_state = DATA_LOW;
                            tick_count_next = 0;
                            bit_count_next = bit_count_reg + 1;
                            data_next = {data_reg[38:0], 1'b1};
                        end
                    end
                end else if (i_tick_10us) begin
                    tick_count_next = tick_count_reg + 1;
                end
            end

            END: begin
                if (i_tick_10us) begin
                    if (tick_count_reg >= 4) begin
                        if(data_reg[7:0] == (data_reg[39:32] + data_reg[31:24] +data_reg[23:16] + data_reg[15:8]))begin
                            n_state = IDLE;
                            dht11_io_next = 1;
                            dht11_io_control_next = 1;
                            done_next = 1;
                            valid_next = 1;
                        end else begin
                            n_state = IDLE;
                            dht11_io_next = 1;
                            dht11_io_control_next = 1;
                            done_next = 1;
                            valid_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end

    // SL
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            c_state              <= IDLE;
            tick_count_reg       <= 0;
            bit_count_reg        <= 0;
            data_reg             <= 0;
            dht11_io_reg         <= 1;
            dht11_io_control_reg <= 1;
            done_reg             <= 0;
            valid_reg            <= 0;
        end else begin
            c_state              <= n_state;
            tick_count_reg       <= tick_count_next;
            bit_count_reg        <= bit_count_next;
            data_reg             <= data_next;
            dht11_io_reg         <= dht11_io_next;
            dht11_io_control_reg <= dht11_io_control_next;
            done_reg             <= done_next;
            valid_reg            <= valid_next;
        end
    end
endmodule

//////////

module tick_10us (
    input  i_clk,
    input  i_reset,
    output o_tick
);
    parameter F_COUNT = 1_000; 
    reg tick_reg;
    assign o_tick = tick_reg;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge i_clk, posedge i_reset) begin
        if (i_reset) begin
            counter_reg <= 0;
            tick_reg    <= 0;
        end else if (counter_reg == (F_COUNT - 1)) begin
            counter_reg <= 0;
            tick_reg    <= 1;
        end else begin
            counter_reg <= counter_reg + 1;
            tick_reg    <= 0;
        end
    end
endmodule

//////////

module edge_detector (
    input  i_clk,
    input  i_reset,
    input  i_dht11_io,
    output o_pos_edge,
    output o_neg_edge
);

    // register
    reg [99:0] q;
    reg q_pos_z, q_neg_z;

    // wire
    wire q_pos, q_neg;

    // CL
    assign q_pos = &q;
    assign q_neg = ~(|q);
    assign o_pos_edge = q_pos & (~q_pos_z);
    assign o_neg_edge = q_neg & (~q_neg_z);

    // SL
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            q <= 0;
            q_pos_z <= 0;
            q_neg_z <= 1;
        end else begin
            q <= {i_dht11_io, q[99:1]};
            q_pos_z <= q_pos;
            q_neg_z <= q_neg;
        end

    end
endmodule

//////////

module dht11_control_unit #(
    parameter F_COUNT = 100_000_000
) (
    input  i_clk,
    input  i_reset,
    output o_tick_1s
);

    // reg
    reg [$clog2(F_COUNT) - 1 : 0] counter_reg;
    reg tick_1s_reg;

    // CL
    assign o_tick_1s = tick_1s_reg;

    // SL
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            counter_reg <= 0;
            tick_1s_reg <= 0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_1s_reg <= 1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_1s_reg <= 0;
            end
        end
    end
endmodule
