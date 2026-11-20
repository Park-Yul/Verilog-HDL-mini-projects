`timescale 1ns / 1ps
module uart_fifo_loop_back (
    input  clk,
    input  reset,
    input  rx,
    input [7:0] fifo_tx_wdata,
    input tx_push,
    output tx,
    output [7:0] fifo_rx_rdata,
    output fifo_rx_pop,
    output tx_full
);
    wire w_baud_tick_x16;
    wire w_rx_done;
    wire [7:0] w_rx_data;
    wire w_fifo_tx_full;


    wire w_fifo_rx_empty;
    wire [7:0] w_fifo_tx_rdata;
    wire w_fifo_tx_empty;
    wire w_tx_busy;

    // CL
    assign fifo_rx_pop = ~w_fifo_rx_empty;



    uart_rx U_UART_RX (
        .clk        (clk),
        .reset      (reset),
        .i_baud_tick(w_baud_tick_x16),  // 16 time divided baud_tick
        .rx         (rx),
        .rx_data    (w_rx_data),
        .rx_done    (w_rx_done)
    );

    fifo U_FIFO_RX (
        .clk(clk),
        .reset(reset),
        .push(w_rx_done),
        .pop(~w_fifo_rx_empty),
        .wdata(w_rx_data),
        .rdata(fifo_rx_rdata),
        .full(), //NC
        .empty(w_fifo_rx_empty)
    );

    fifo U_FIFO_TX (
        .clk(clk),
        .reset(reset),
        .push(tx_push),//
        .pop(~w_tx_busy),
        .wdata(fifo_tx_wdata),
        .rdata(w_fifo_tx_rdata),
        .full(tx_full), 
        .empty(w_fifo_tx_empty)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .tx_start   (~w_fifo_tx_empty),     // 1 tick pulse from debouncer. tx_start is random time input > not sync with i_baud_tick > create wait state : tx_start>i_baud_tick
        .tx_data(w_fifo_tx_rdata),
        .i_baud_tick(w_baud_tick_x16),  //external signal
        .tx_busy(w_tx_busy),
        .tx_done(),
        .tx(tx)
    );

    baud_tick_x16 U_BAUD_TICK_X16 (
        .clk        (clk),
        .reset      (reset),
        .o_baud_tick(w_baud_tick_x16)
    );
endmodule
