`timescale 1ns / 1ps `timescale 1ns / 1ps
module tb_top #(
    parameter SYS_CLK = 100_000_000,
    parameter BAUD    = 9600,
    parameter DATA_WIDTH = 8
);
    reg          i_clk;
    reg          i_reset;
    reg  [  2:0] i_sw_sel;
    reg  [15:12] i_sw_lap;
    reg          i_btn_L;
    reg          i_btn_R;
    reg          i_btn_U;
    reg          i_btn_D;
    reg          i_rx;
    reg          i_echo;
    wire [  2:0] o_led_sel;
    wire [15:12] o_led_lap;
    wire [  3:0] o_fnd_com;
    wire [  7:0] o_fnd_data;
    wire         o_trigger;
    wire         o_tx;

    wire         io_dht11;

    // integer
    integer i = 0, j = 0;

    // register for task
    reg [DATA_WIDTH -1:0] receive_data;
    reg [DATA_WIDTH -1:0] send_data;

    // delay parameter  
    parameter ns_10 = 10;
    parameter BAUD_DELAY = (SYS_CLK / BAUD) * 10;

    // DUT instantiation
    top DUT (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_sw_sel(i_sw_sel),
        .i_sw_lap(i_sw_lap),
        .i_btn_L(i_btn_L),
        .i_btn_R(i_btn_R),
        .i_btn_U(i_btn_U),
        .i_btn_D(i_btn_D),
        .i_rx(i_rx),
        .i_echo(i_echo),
        .o_led_sel(o_led_sel),
        .o_led_lap(o_led_lap),
        .o_fnd_com(o_fnd_com),
        .o_fnd_data(o_fnd_data),
        .o_trigger(o_trigger),
        .o_tx(o_tx),
        .io_dht11(io_dht11)
    );

    // clock generation
    always #5 i_clk = ~i_clk;

    // task : pc uart sender
    task SENDER_FOR_UART_RX();
        begin
            // START
            i_rx = 0;
            #(BAUD_DELAY);

            // DATA
            for (i = 0; i < 8; i = i + 1) begin
                i_rx = send_data[i];
                #(BAUD_DELAY);
            end

            // STOP
            i_rx = 1;
            #(BAUD_DELAY);
        end
    endtask

    // task : pc uart receiver
    task RECEIVER_FOR_UART_TX();
        begin
            wait (~o_tx);
            #(BAUD_DELAY / 2);
            if (o_tx) $display("%t : start bitt error", $time);
            for (j = 0; j < 8; j = j + 1) begin
                #(BAUD_DELAY);
                receive_data[j] = o_tx;
            end
            #(BAUD_DELAY);
            if (~o_tx) $display("%t : stop bit error", $time);
        end
    endtask


    // scenario
    initial begin
        i_clk = 0;
        i_reset = 1;
        i_sw_sel = 0;
        i_sw_lap = 0;
        i_btn_L = 0;
        i_btn_R = 0;
        i_btn_U = 0;
        i_btn_D = 0;
        i_rx = 1;
        i_echo = 0;
        #ns_10;
        i_reset = 0;
        #ns_10

        // simulation for loopback
        send_data = 8'h31;
        SENDER_FOR_UART_RX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        RECEIVER_FOR_UART_TX();
        #100;
        $stop;
    end
endmodule


//////////

module tb_mux_4x1 #(
    parameter BIT_WIDTH = 8
);
    reg [BIT_WIDTH - 1 : 0] in0;
    reg [BIT_WIDTH - 1 : 0] in1;
    reg [BIT_WIDTH - 1 : 0] in2;
    reg [BIT_WIDTH - 1 : 0] in3;
    reg [1:0] sel;
    wire [BIT_WIDTH - 1 : 0] mux_out;

    // integer
    integer i = 0;

    // DUT instantiation
    mux_4x1 #(
        .BIT_WIDTH(BIT_WIDTH)
    ) DUT (
        .in0    (in0),
        .in1    (in1),
        .in2    (in2),
        .in3    (in3),
        .sel    (sel),
        .mux_out(mux_out)
    );

    // scenario
    initial begin
        for (i = 0; i < 10; i = i + 1) begin
            in0 = $urandom % 256;
            in1 = $urandom % 256;
            in2 = $urandom % 256;
            in3 = $urandom % 256;
            sel = $urandom % 4;
            #100;
        end
    end
endmodule
