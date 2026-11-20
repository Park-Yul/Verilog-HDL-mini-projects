`timescale 1ns / 1ps
module top #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
) (
    input i_clk,
    input i_reset,
    input [2:0] i_sw_sel,
    input [15:12] i_sw_lap,
    input i_btn_L,
    input i_btn_R,
    input i_btn_U,
    input i_btn_D,
    input i_rx,
    input i_echo,
    output [2:0] o_led_sel,
    output [15:12] o_led_lap,
    output [3:0] o_fnd_com,
    output [7:0] o_fnd_data,
    output o_trigger,
    output o_tx,
    inout io_dht11
);

    // wire for demux_1x2
    wire w_btn_L, w_btn_R, w_btn_U, w_btn_D;
    wire [3 : 0] w_demux_out0;
    wire [3 : 0] w_demux_out1;

    // wire for ascii_decoder 
    wire [7:0] w_rx_data;
    wire w_rx_done;
    wire [14:0] w_dec_out;
    wire [4:0] w_stopwatch_dec;
    wire [3:0] w_watch_dec;
    wire [5:0] w_sender_dec;

    // wire for stopwatch
    wire w_run_stop, w_clear, w_mode, w_lap;
    wire [MSEC_WIDTH-1:0] w_msec_stopwatch;
    wire [SEC_WIDTH-1:0] w_sec_stopwatch;
    wire [MIN_WIDTH-1:0] w_min_stopwatch;
    wire [HOUR_WIDTH-1:0] w_hour_stopwatch;

    // wire for watch
    wire w_hour_sel;
    wire w_min_sel;
    wire w_sec_sel;
    wire w_up_count;
    wire w_down_count;
    wire [MSEC_WIDTH-1:0] w_msec_watch;
    wire [SEC_WIDTH-1:0] w_sec_watch;
    wire [MIN_WIDTH-1:0] w_min_watch;
    wire [HOUR_WIDTH-1:0] w_hour_watch;

    // wire for sr04
    wire w_sr04_tick_500ms;
    wire w_sr04_done;
    wire [8:0] w_distance;
    wire [7:0] w_distance_1_to_10;
    wire [7:0] w_distance_100_to_1000;

    // wire for dht11
    wire w_dht11_tick_1s;
    wire w_dht11_done;
    wire [39:0] w_data;
    wire [7:0] w_rh_int, w_rh_dec, w_t_int, w_t_dec;

    // wire for ascii_sender
    wire w_watch_set;
    wire [7:0] w_sender_data;
    wire w_tx_push;
    wire w_tx_full;

    // wire for mux
    wire [7:0] w_msec_fnd;
    wire [7:0] w_sec_fnd;
    wire [7:0] w_min_fnd;
    wire [7:0] w_hour_fnd;

    // CL for ascii_dec
    assign w_stopwatch_dec = w_dec_out[8:4];
    assign w_watch_dec     = w_dec_out[3:0];
    assign w_sender_dec    = w_dec_out[14:9];

    // CL for dht11
    assign w_rh_int        = w_data[39:32];
    assign w_rh_dec        = w_data[31:24];
    assign w_t_int         = w_data[23:16];
    assign w_t_dec         = w_data[15:8];

    // CL for ascii_sender
    assign w_watch_set     = |{w_hour_sel, w_min_sel, w_sec_sel};

    // CL for top
    assign o_led_sel       = i_sw_sel;

    // btn_debounce_4 instantiation
    btn_debounce_4 U_BTN_DEBOUNCE (
        .clk    (i_clk),
        .reset  (i_reset),
        .i_btn_L(i_btn_L),
        .i_btn_R(i_btn_R),
        .i_btn_U(i_btn_U),
        .i_btn_D(i_btn_D),
        .o_btn_L(w_btn_L),
        .o_btn_R(w_btn_R),
        .o_btn_U(w_btn_U),
        .o_btn_D(w_btn_D)
    );

    // demux_1x2 instantiation
    demux_1x4 U_DEMUX_1x4 (
        .i_in  ({w_btn_L, w_btn_R, w_btn_U, w_btn_D}),
        .i_sel (i_sw_sel[2:1]),
        .o_out0(w_demux_out0),
        .o_out1(w_demux_out1),
        .o_out2(),
        .o_out3()
    );

    // UART FIFO instantiation
    uart_fifo_loop_back U_UART_FIFO_LOOPBACK (

        .clk          (i_clk),
        .reset        (i_reset),
        .rx           (i_rx),
        .fifo_tx_wdata(w_sender_data),
        .tx_push      (w_tx_push),
        .tx           (o_tx),
        .fifo_rx_rdata(w_rx_data),
        .fifo_rx_pop  (w_rx_done),
        .tx_full      (w_tx_full)
    );
    // ascii_decoder instantiation
    ascii_dec U_ASCII_DEC (
        .clk    (i_clk),
        .reset  (i_reset),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .dec_out(w_dec_out)
    );

    // stopwatch_control_unit instantiation
    stopwatch_control_unit U_STOPWATCH_CONTROL_UNIT (
        .clk       (i_clk),
        .reset     (i_reset),
        .i_run     (w_demux_out0[3]),
        .i_stop    (w_demux_out0[3]),
        .i_clear   (w_demux_out0[2]),
        .i_mode    (w_demux_out0[1]),
        .i_lap     (w_demux_out0[0]),
        .uart_run  (w_stopwatch_dec[4]),
        .uart_stop (w_stopwatch_dec[3]),
        .uart_clear(w_stopwatch_dec[2]),
        .uart_mode (w_stopwatch_dec[1]),
        .uart_lap  (w_stopwatch_dec[0]),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear),
        .o_mode    (w_mode),
        .o_lap     (w_lap)
    );
    // stopwatch_datapath instantiation
    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (i_clk),
        .reset   (i_reset),
        .run_stop(w_run_stop),
        .clear   (w_clear),
        .mode    (w_mode),
        .lap     (w_lap),
        .sw      (i_sw_lap),
        .msec_out(w_msec_stopwatch),
        .sec_out (w_sec_stopwatch),
        .min_out (w_min_stopwatch),
        .hour_out(w_hour_stopwatch),
        .led_out (o_led_lap)
    );

    // watch_control_unit instantiation
    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk          (i_clk),
        .reset        (i_reset),
        .i_change_L   (w_demux_out1[3]),
        .i_change_R   (w_demux_out1[2]),
        .i_change_U   (w_demux_out1[1]),
        .i_change_D   (w_demux_out1[0]),
        .uart_change_L(w_watch_dec[3]),
        .uart_change_R(w_watch_dec[2]),
        .uart_change_U(w_watch_dec[1]),
        .uart_change_D(w_watch_dec[0]),
        .o_hour_sel   (w_hour_sel),
        .o_min_sel    (w_min_sel),
        .o_sec_sel    (w_sec_sel),
        .o_up_count   (w_up_count),
        .o_down_count (w_down_count)
    );

    // watch_datapath instantiation
    watch_datapath U_WATCH_DATAPATH (
        .clk         (i_clk),
        .reset       (i_reset),
        .i_hour_sel  (w_hour_sel),
        .i_min_sel   (w_min_sel),
        .i_sec_sel   (w_sec_sel),
        .i_up_count  (w_up_count),
        .i_down_count(w_down_count),
        .msec        (w_msec_watch),
        .sec         (w_sec_watch),
        .min         (w_min_watch),
        .hour        (w_hour_watch)
    );

    // sr04_control_unit instantiation
    sr04_control_unit U_SR04_CONTROL_UNIT (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .o_tick_1s(w_sr04_tick_500ms)
    );

    // sr04_controller instantiation
    sr04_controller U_SR04_CONTROLLER (
        .clk     (i_clk),
        .reset   (i_reset),
        .start   (w_sr04_tick_500ms),
        .echo    (i_echo),
        .trigger (o_trigger),
        .busy    (),
        .done    (w_sr04_done),
        .distance(w_distance)
    );

    // dht11_control_unit instantiation
    dht11_control_unit U_DHT_CONTROL_UNIT (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .o_tick_1s(w_dht11_tick_1s)
    );

    // dht11_controller instantiation
    dht11_controller U_DHT11_CONTROLLER (
        .i_clk   (i_clk),
        .i_reset (i_reset),
        .i_start (w_dht11_tick_1s),
        .o_data  (w_data),
        .o_done  (w_dht11_done),
        .o_valid (),
        .dht11_io(io_dht11)
    );

    // digit_spliter_dht instantiation
    digit_splitter_sr04 U_DIGIT_SPLITTER_SR04 (
        .ds_in            (w_distance),
        .digit_1_to_10    (w_distance_1_to_10),
        .digit_100_to_1000(w_distance_100_to_1000)
    );

    // mux_4x1 instantiation
    mux_4x1 U_MUX_4x1_MSEC (
        .in0    ({1'b0, w_msec_stopwatch}),
        .in1    ({1'b0, w_msec_watch}),
        .in2    (w_distance_1_to_10),
        .in3    (w_rh_dec),
        .sel    (i_sw_sel[2:1]),
        .mux_out(w_msec_fnd)
    );

    mux_4x1 U_MUX_4x1_SEC (
        .in0    ({2'b0, w_sec_stopwatch}),
        .in1    ({2'b0, w_sec_watch}),
        .in2    (w_distance_100_to_1000),
        .in3    (w_rh_int),
        .sel    (i_sw_sel[2:1]),
        .mux_out(w_sec_fnd)
    );

    mux_4x1 U_MUX_4x1_MIN (
        .in0    ({2'b0, w_min_stopwatch}),
        .in1    ({2'b0, w_min_watch}),
        .in2    (8'b0),
        .in3    (w_t_dec),
        .sel    (i_sw_sel[2:1]),
        .mux_out(w_min_fnd)
    );

    mux_4x1 U_MUX_4x1_HOUR (
        .in0    ({3'b0, w_hour_stopwatch}),
        .in1    ({3'b0, w_hour_watch}),
        .in2    (8'b0),
        .in3    (w_t_int),
        .sel    (i_sw_sel[2:1]),
        .mux_out(w_hour_fnd)
    );

    // ascii_sender instantiation
    ascii_sender U_ASCII_SENDER (
        .clk        (i_clk),
        .rst        (i_reset),
        .cmd        (w_sender_dec),
        .sw_mode    (w_mode),
        .sw_run     (w_run_stop),
        .watch_set  (w_watch_set),
        .distance   (w_distance),
        .humidity   (w_rh_int),
        .temperature(w_t_int),
        .tx_data    (w_sender_data),
        .tx_push    (w_tx_push),
        .tx_full    (w_tx_full)
    );

    // fnd_controller instantiation
    top_fnd_controller U_FND_CONTROLLER (
        .clk         (i_clk),
        .reset       (i_reset),
        .i_hour_sel  (w_hour_sel),
        .i_min_sel   (w_min_sel),
        .i_sec_sel   (w_sec_sel),
        .display_mode(i_sw_sel),
        .msec        (w_msec_fnd),
        .sec         (w_sec_fnd),
        .min         (w_min_fnd),
        .hour        (w_hour_fnd),
        .fnd_com     (o_fnd_com),
        .fnd_data    (o_fnd_data)
    );


endmodule

//////////

module demux_1x4 #(
    parameter BIT_NUM = 4
) (
    input [BIT_NUM -1 : 0] i_in,
    input [1:0] i_sel,
    output reg [BIT_NUM-1:0] o_out0,
    output reg [BIT_NUM-1:0] o_out1,
    output reg [BIT_NUM-1:0] o_out2,
    output reg [BIT_NUM-1:0] o_out3
);
    // Combinational Logic
    always @(*) begin
        o_out0 = 0;
        o_out1 = 0;
        o_out2 = 0;
        o_out3 = 0;
        case (i_sel)
            2'b00: begin
                o_out0 = i_in;
                o_out1 = 0;
                o_out2 = 0;
                o_out3 = 0;
            end
            2'b01: begin

                o_out0 = 0;
                o_out1 = i_in;
                o_out2 = 0;
                o_out3 = 0;
            end
            2'b10: begin
                o_out0 = 0;
                o_out1 = 0;
                o_out2 = i_in;
                o_out3 = 0;
            end
            2'b11: begin
                o_out0 = 0;
                o_out1 = 0;
                o_out2 = 0;
                o_out3 = i_in;
            end
        endcase
    end
endmodule

///////////
module mux_4x1 #(
    parameter BIT_WIDTH = 8
) (
    input [BIT_WIDTH - 1 : 0] in0,
    input [BIT_WIDTH - 1 : 0] in1,
    input [BIT_WIDTH - 1 : 0] in2,
    input [BIT_WIDTH - 1 : 0] in3,
    input [1:0] sel,
    output reg [BIT_WIDTH - 1 : 0] mux_out
);

    // SL
    always @(*) begin
        mux_out = 0;
        case (sel)
            2'b00: mux_out = in0;
            2'b01: mux_out = in1;
            2'b10: mux_out = in2;
            2'b11: mux_out = in3;
        endcase
    end
endmodule

//////////

module digit_splitter_sr04 #(
    parameter BIT_WIDTH = 9
) (
    input [(BIT_WIDTH - 1):0] ds_in,
    output [7:0] digit_1_to_10,
    output [7:0] digit_100_to_1000
);
    assign digit_1_to_10 = ds_in % 100;
    assign digit_100_to_1000 = (ds_in / 100) % 100;

endmodule
