`timescale 1ns / 1ps
module uart_tx (
    input clk,
    input reset,
    input        tx_start,     // 1 tick pulse from debouncer. tx_start is random time input > not sync with i_baud_tick > create wait state : tx_start>i_baud_tick
    input [7:0] tx_data,
    input i_baud_tick,  //external signal 9600_x16 tick = 6.51us period
    output tx_busy,
    output tx_done,
    output tx
);

    localparam [1:0] IDLE = 2'h0, START = 2'h1;
    localparam [1:0] DATA = 2'h2;
    localparam [1:0] STOP = 2'h3;


    reg [2:0] c_state, n_state;
    reg [3:0] tick_count_reg, tick_count_next;
    reg tx_reg, tx_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [7:0] data_reg, data_next;
    reg tx_busy_reg, tx_busy_next;
    reg tx_done_reg, tx_done_next;

    assign tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state        <= IDLE;
            tick_count_reg <= 4'b0;
            bit_count_reg  <= 3'd0;
            tx_reg         <= 1'b1;
            data_reg       <= 8'h00;
            tx_busy_reg    <= 1'b0;
            tx_done_reg    <= 1'b0;
        end else begin
            c_state        <= n_state;
            tick_count_reg <= tick_count_next;
            bit_count_reg  <= bit_count_next;
            tx_reg         <= tx_next;
            data_reg       <= data_next;
            tx_busy_reg    <= tx_busy_next;
            tx_done_reg    <= tx_done_next;
        end
    end

    // next CL
    always @(*) begin
        n_state         = c_state;
        tick_count_next = tick_count_reg;
        bit_count_next  = bit_count_reg;
        tx_next         = tx_reg;
        data_next       = data_reg;
        tx_busy_next    = tx_busy_reg;
        tx_done_next    = tx_done_reg;
        case (c_state)
            IDLE: begin
                tick_count_next = 0;
                //output
                tx_next = 1'b1;
                tx_busy_next = 1'b0;
                tx_done_next = 1'b0;
                if (tx_start == 1) begin
                    data_next = tx_data;
                    tx_busy_next = 1'b1;  // wait why here?
                    n_state = START;
                end
            end

            START: begin
                tx_next = 1'b0;
                bit_count_next = 3'd0;  //  why here!? why not IDLE?
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        n_state = DATA;
                        tick_count_next = 0;
                    end else tick_count_next = tick_count_reg + 1;

                end
            end

            DATA: begin
                tx_next = data_reg[0];
                if (i_baud_tick == 1) begin
                    if (tick_count_reg == 15) begin
                        data_next = {1'b0, data_reg[7:1]};
                        tick_count_next = 0;
                        //data_next = data_reg >> 1;
                        if (bit_count_reg == 7) n_state = STOP;
                        else begin
                            n_state        = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (i_baud_tick == 1) begin
                    if (tick_count_reg == 15) begin
                        tx_busy_next = 1'b0;
                        tx_done_next = 1'b1;  //tx_done tick
                        n_state = IDLE;
                    end else tick_count_next = tick_count_reg + 1;
                end
            end

        endcase
    end
endmodule

module uart_rx (
    input        clk,
    input        reset,
    input        i_baud_tick,  // 16 time divided baud_tick
    input        rx,
    output [7:0] rx_data,
    output       rx_done
);

    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] c_state, n_state;
    reg [3:0] tick_count_reg, tick_count_next;  // 16 time divided baud_tick
    reg [2:0] bit_count_reg, bit_count_next;
    reg [7:0] data_reg, data_next;

    //reg rx done reg; // for CL output
    reg rx_done_reg, rx_done_next;  // for SL output

    assign rx_done = rx_done_reg;
    assign rx_data = data_reg;



    //sequential logic
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= IDLE;
            tick_count_reg <= 0;
            bit_count_reg <= 0;
            data_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state <= n_state;
            tick_count_reg <= tick_count_next;
            bit_count_reg <= bit_count_next;
            data_reg <= data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    //combinational Logic
    always @(*) begin
        n_state         = c_state;
        tick_count_next = tick_count_reg;
        bit_count_next  = bit_count_reg;
        data_next       = data_reg;
        // rx_done_reg     = 0;
        rx_done_next    = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 0;
                bit_count_next  = 0;
                if (i_baud_tick) begin
                    if (!rx) begin
                        if (tick_count_reg == 7) begin
                            n_state = START;
                            tick_count_next = 0;
                        end else begin
                            tick_count_next = tick_count_reg + 1;
                        end
                    end else begin
                        //data_next = 0;  //this code can't hold previous data in IDLE : erase
                        tick_count_next = 0;
                    end
                end
            end
            START: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        n_state = DATA;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (i_baud_tick) begin
                    if (tick_count_reg == 0) begin
                        //data_next = data_reg[bit_count_reg]; // PIPO, bit indexing

                        //SIPO
                        data_next = {
                            rx, data_reg[7:1]
                        };  // MSB rx first in > then shift to LSB
                    end
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (i_baud_tick) begin
                    //if (tick_count_reg == 7) begin
                        rx_done_next = 1;  //for SL output
                        //rx_done_reg = 1;  //for CL output
                        n_state = IDLE;
                    //end else begin
                        //tick_count_next = tick_count_reg + 1;
                    end
                end
            
        endcase
    end
endmodule


module baud_tick_x16 (
    input  clk,
    input  reset,
    output o_baud_tick
);
    //9600bps baud tick gen
    parameter MAX_COUNT = 100_000_000 / (9600 * 16);
    //parameter MAX_COUNT = 10416;

    reg  [$clog2(MAX_COUNT) - 1:0] count_reg;
    wire [$clog2(MAX_COUNT) - 1:0] count_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_next;
        end
    end

    assign count_next  = (count_reg == MAX_COUNT - 1) ? 0 : count_reg + 1;
    assign o_baud_tick = (count_reg == MAX_COUNT - 1) ? 1 : 0;
endmodule

