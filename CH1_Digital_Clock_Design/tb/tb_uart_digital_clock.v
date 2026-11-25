`timescale 1ns / 1ps

module tb_stopwatch_control_unit;

    reg clk;
    reg reset;
    reg i_run, i_stop, i_clear, i_mode, i_lap;
    reg uart_run, uart_stop, uart_clear, uart_mode, uart_lap;
    wire o_run_stop;
    wire o_clear;
    wire o_mode;
    wire o_lap;

    // delay parameter
    parameter ns_10 = 10;
    parameter WAIT = 1_000;

    // DUT instantiation
    stopwatch_control_unit DUT (
        .clk(clk),
        .reset(reset),
        .i_run(i_run),
        .i_stop(i_stop),
        .i_clear(i_clear),
        .i_mode(i_mode),
        .i_lap(i_lap),
        .uart_run(uart_run),
        .uart_stop(uart_stop),
        .uart_clear(uart_clear),
        .uart_mode(uart_mode),
        .uart_lap(uart_lap),
        .o_run_stop(o_run_stop),
        .o_clear(o_clear),
        .o_mode(o_mode),
        .o_lap(o_lap)
    );

    // clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        i_run = 0;
        i_stop = 0;
        i_clear = 0;
        i_mode = 0;
        i_lap = 0;
        uart_run = 0;
        uart_stop = 0;
        uart_clear = 0;
        uart_mode = 0;
        uart_lap = 0;
        #ns_10;

        reset = 0;
        #ns_10;

        #100 $finish;
    end
endmodule

//////////

module tb_watch_control_unit;
    reg clk;
    reg reset;
    reg i_change_L, i_change_R, i_change_U, i_change_D;
    reg uart_change_L, uart_change_R, uart_change_U, uart_change_D;
    wire o_hour_sel;
    wire o_min_sel;
    wire o_sec_sel;
    wire o_up_count;
    wire o_down_count;


    // delay parameter
    parameter ns_10 = 10;
    parameter WAIT = 1_000;

    // DUT instantiation
    watch_control_unit DUT (
        .clk(clk),
        .reset(reset),
        .i_change_L(i_change_L),
        .i_change_R(i_change_R),
        .i_change_U(i_change_U),
        .i_change_D(i_change_D),
        .uart_change_L(uart_change_L),
        .uart_change_R(uart_change_R),
        .uart_change_U(uart_change_U),
        .uart_change_D(uart_change_D),
        .o_hour_sel(o_hour_sel),
        .o_min_sel(o_min_sel),
        .o_sec_sel(o_sec_sel),
        .o_up_count(o_up_count),
        .o_down_count(o_down_count)
    );

    // clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        i_change_L = 0;
        i_change_R = 0;
        i_change_U = 0;
        i_change_D = 0;
        uart_change_L = 0;
        uart_change_R = 0;
        uart_change_U = 0;
        uart_change_D = 0;
        #ns_10;

        reset = 0;
        #ns_10;

        // Add stimulus here
        #100 $finish;
    end
endmodule

//////////

module tb_ascii_dec #(
    parameter DATA_WIDTH = 8
);
    reg clk;
    reg reset;
    reg [DATA_WIDTH - 1 : 0] rx_data;
    reg rx_done;
    wire [8:0] dec_out;

    // DUT instantiation
    ascii_dec #(
        .DATA_WIDTH(DATA_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .dec_out(dec_out)
    );


    // delay parameter
    parameter ns_10 = 10;
    parameter WAIT = 1_000;

    // clock generation
    always #5 clk = ~clk;

    initial begin
        reset   = 1;
        rx_data = 8'h00;
        rx_done = 0;
        #ns_10;

        reset = 0;
        #ns_10;

        #100 $finish;
    end
endmodule
