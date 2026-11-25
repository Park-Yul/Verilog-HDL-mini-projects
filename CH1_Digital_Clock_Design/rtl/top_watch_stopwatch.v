`timescale 1ns / 1ps

module top_watch_stopwatch #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH = 6,
    parameter MIN_WIDTH = 6,
    parameter HOUR_WIDTH = 5,
    parameter BIT_NUM = 4,
    parameter SYS_CLK = 100_000_000,
    parameter BAUD = 9_600,
    parameter DATA_WIDTH = 8

) (
    input clk,
    input reset,
    input btn_L,
    input btn_R,
    input btn_U,
    input btn_D,
    input rx,
    input [15:12] sw_lap,
    input [1:0] sw_sel,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [15:12] led_lap,
    output [1:0] led_sel,
    output tx
);
    assign led_sel[1:0] = sw_sel[1:0];

    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;

    // btn_debounce instantiation
    btn_debounce_4 U_BTN_DEBOUNCE_4 (
        .clk(clk),
        .reset(reset),
        .i_btn_L(btn_L),
        .i_btn_R(btn_R),
        .i_btn_U(btn_U),
        .i_btn_D(btn_D),
        .o_btn_L(w_btn_L),
        .o_btn_R(w_btn_R),
        .o_btn_U(w_btn_U),
        .o_btn_D(w_btn_D)
    );

    wire [BIT_NUM - 1 : 0] demux_out0;
    wire [BIT_NUM - 1 : 0] demux_out1;

    // demux_1x2 instantiation
    demux_1x2 #(
        .BIT_NUM(BIT_NUM)
    ) U_DEMUX_1X2 (
        .i_in  ({w_btn_L, w_btn_R, w_btn_U, w_btn_D}),
        .i_sel (sw_sel[1]),
        .o_out0(demux_out0),
        .o_out1(demux_out1)
    );

    wire [DATA_WIDTH - 1:0] w_data;
    wire w_done;

    // uart_loopback instantiation
    uart_loopback #(
        .SYS_CLK   (SYS_CLK),
        .BAUD      (BAUD),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_UART_LOOPBACK (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .rx_data(w_data),
        .rx_done(w_done),
        .tx(tx)
    );

    wire [8:0] w_dec_out;

    // ascii_dec instantiation
    ascii_dec #(
        .DATA_WIDTH(DATA_WIDTH)
    ) U_ASXII_DEC (
        .clk(clk),
        .reset(reset),
        .rx_data(w_data),
        .rx_done(w_done),
        .dec_out(w_dec_out)
    );

    wire w_run_stop, w_clear, w_mode, w_lap;

    // stopwatch_control_unit instantiation
    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_run(demux_out0[3]),
        .i_stop(demux_out0[3]),
        .i_clear(demux_out0[2]),
        .i_mode(demux_out0[1]),
        .i_lap(demux_out0[0]),
        .uart_run(w_dec_out[8]),
        .uart_stop(w_dec_out[7]),
        .uart_clear(w_dec_out[6]),
        .uart_mode(w_dec_out[5]),
        .uart_lap(w_dec_out[4]),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear),
        .o_mode(w_mode),
        .o_lap(w_lap)
    );

    wire [MSEC_WIDTH-1:0] w_msec_stopwatch;
    wire [ SEC_WIDTH-1:0] w_sec_stopwatch;
    wire [ MIN_WIDTH-1:0] w_min_stopwatch;
    wire [HOUR_WIDTH-1:0] w_hour_stopwatch;


    // stopwatch datapath instantiation
    stopwatch_datapath #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_STOPWATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .run_stop(w_run_stop),
        .clear(w_clear),
        .mode(w_mode),
        .lap(w_lap),
        .msec_out(w_msec_stopwatch),
        .sec_out(w_sec_stopwatch),
        .min_out(w_min_stopwatch),
        .hour_out(w_hour_stopwatch),
        .sw(sw_lap),
        .led_out(led_lap)
    );

    wire w_hour_sel, w_min_sel, w_sec_sel, w_up_count, w_down_count;

    // watch_control_unit instantiation
    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk(clk),
        .reset(reset),
        .i_change_L(demux_out1[3]),
        .i_change_R(demux_out1[2]),
        .i_change_U(demux_out1[1]),
        .i_change_D(demux_out1[0]),
        .uart_change_L(w_dec_out[3]),
        .uart_change_R(w_dec_out[2]),
        .uart_change_U(w_dec_out[1]),
        .uart_change_D(w_dec_out[0]),
        .o_hour_sel(w_hour_sel),
        .o_min_sel(w_min_sel),
        .o_sec_sel(w_sec_sel),
        .o_up_count(w_up_count),
        .o_down_count(w_down_count)
    );

    wire [MSEC_WIDTH-1:0] w_msec_watch;
    wire [ SEC_WIDTH-1:0] w_sec_watch;
    wire [ MIN_WIDTH-1:0] w_min_watch;
    wire [HOUR_WIDTH-1:0] w_hour_watch;

    //  watch_datapath instantiation
    watch_datapath #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .i_hour_sel(w_hour_sel),
        .i_min_sel(w_min_sel),
        .i_sec_sel(w_sec_sel),
        .i_up_count(w_up_count),
        .i_down_count(w_down_count),
        .msec(w_msec_watch),
        .sec(w_sec_watch),
        .min(w_min_watch),
        .hour(w_hour_watch)
    );

    wire [MSEC_WIDTH-1:0] w_muxout_msec;
    wire [ SEC_WIDTH-1:0] w_muxout_sec;
    wire [ MIN_WIDTH-1:0] w_muxout_min;
    wire [HOUR_WIDTH-1:0] w_muxout_hour;

    // mux_2x1_sw1 instantiation
    mux_2x1_sw1 #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MUX_2x1_MSEC (
        .in0(w_msec_stopwatch),
        .in1(w_msec_watch),
        .i_sel(sw_sel[1]),
        .mux_out(w_muxout_msec)
    );
    mux_2x1_sw1 #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_MUX_2x1_SEC (
        .in0(w_sec_stopwatch),
        .in1(w_sec_watch),
        .i_sel(sw_sel[1]),
        .mux_out(w_muxout_sec)
    );
    mux_2x1_sw1 #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MUX_2x1_MIN (
        .in0(w_min_stopwatch),
        .in1(w_min_watch),
        .i_sel(sw_sel[1]),
        .mux_out(w_muxout_min)
    );
    mux_2x1_sw1 #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_MUX_2x1_HOUR (
        .in0(w_hour_stopwatch),
        .in1(w_hour_watch),
        .i_sel(sw_sel[1]),
        .mux_out(w_muxout_hour)
    );


    // top_fnd_controller instantiation
    top_fnd_controller #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_WATCH_FND_CONTROLLER (
        .clk(clk),
        .reset(reset),
        .i_hour_sel(w_hour_sel),
        .i_min_sel(w_min_sel),
        .i_sec_sel(w_sec_sel),
        .display_mode(sw_sel),
        .msec(w_muxout_msec),
        .sec(w_muxout_sec),
        .min(w_muxout_min),
        .hour(w_muxout_hour),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
endmodule

//////////

module mux_2x1_sw1 #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in0,
    input [BIT_WIDTH-1:0] in1,
    input i_sel,
    output reg [BIT_WIDTH-1:0] mux_out
);
    always @(*) begin
        if (i_sel) begin
            mux_out = in1;  //deafult: stopwatch
        end else begin
            mux_out = in0;  // watch
        end
    end

endmodule
