`timescale 1ns / 1ps
module tb_top_fnd_controller #(
    parameter MSEC_WIDTH = 8,
    parameter SEC_WIDTH  = 8,
    parameter MIN_WIDTH  = 8,
    parameter HOUR_WIDTH = 8
);
    reg                      clk;
    reg                      reset;
    reg                      i_hour_sel;
    reg                      i_min_sel;
    reg                      i_sec_sel;
    reg     [           2:0] display_mode;
    reg     [MSEC_WIDTH-1:0] msec;
    reg     [ SEC_WIDTH-1:0] sec;
    reg     [ MIN_WIDTH-1:0] min;
    reg     [HOUR_WIDTH-1:0] hour;
    wire    [           3:0] fnd_com;
    wire    [           7:0] fnd_data;

    // integer
    integer                  i = 0;

    // DUT instantiation
    top_fnd_controller #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) DUT (
        .clk         (clk),
        .reset       (reset),
        .i_hour_sel  (i_hour_sel),
        .i_min_sel   (i_min_sel),
        .i_sec_sel   (i_sec_sel),
        .display_mode(display_mode),
        .msec        (msec),
        .sec         (sec),
        .min         (min),
        .hour        (hour),
        .fnd_com     (fnd_com),
        .fnd_data    (fnd_data)
    );

    // clk generation
    always #5 clk = ~clk;

    // scenario
    initial begin
        clk   = 0;
        reset = 1;
        @(negedge clk);
        reset = 0;

        for (i = 0; i < 10; i = i + 1) begin
            @(posedge clk) #1;
            i_hour_sel   = $urandom % 2;
            i_min_sel    = $urandom % 2;
            i_sec_sel    = $urandom % 2;
            display_mode = $urandom % 4;
            msec         = $urandom % 100;
            sec          = $urandom % 60;
            min          = $urandom % 60;
            hour         = $urandom % 24;
            #(20_000_000);
        end
        #100;
        $stop;
    end
endmodule
