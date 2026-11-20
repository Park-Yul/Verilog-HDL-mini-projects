`timescale 1ns / 1ps
module tb_top_watch_stopwatch #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
);
    reg clk;
    reg reset;
    reg [15:13] sw_lap;
    reg [1:0] sw_sel;
    reg btn_L;  
    reg btn_R;  
    reg btn_U;  
    reg btn_D;  
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [15:0]led;

    // DUT instantiation
    top_watch_stopwatch #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH (SEC_WIDTH),
        .MIN_WIDTH (MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .sw({sw_lap, 11'b0, sw_sel}),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .btn_U(btn_U),
        .btn_D(btn_D),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    // Delay parameter
    parameter us_10 = 1_000 * 10;
    parameter ms_10 = 1_000_000 * 10;


    // clk generation
    always #5 clk = ~clk;

    // integer delclaration for loop
    integer i;

    // scenario
    initial begin
        clk = 0;
        reset = 1;
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #10;
        reset = 0;

        // #1 Stopwatch Down Count Check 2s
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0010;
        #(20 * us_10);
        
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b1000;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * ms_10);

        // #2 Stopwatch 1st lap save
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * us_10);

        // #3 Stopwatch Up Count Check 3s
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b1000;
        #(20 * us_10);
        
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0010;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b1000;
        #(20 * us_10);
        
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(30 * ms_10);

        // #4 Stopwatch 1st lap save
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * us_10);

        // #5 Stopwatch  display min_hour(check 1s)
        sw_lap = 3'b000;
        sw_sel = 2'b01;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(10 * ms_10);

        // #6 Stopwatch 2nd lap save
        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * us_10);

        // #7 Stopwatch 1st lap save
        sw_lap = 3'b001;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        # ms_10;

        sw_lap = 3'b011;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        # ms_10;

        sw_lap = 3'b111;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        # ms_10;

        // #8 Hour Down Count
        sw_lap = 3'b111;
        sw_sel = 2'b11;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0100;
        #(20 * us_10);

        for (i = 0; i < 13; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #9 Min Down Count
        sw_lap = 3'b111;
        sw_sel = 2'b11;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0100;
        #(20 * us_10);

        for (i = 0; i < 11; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #10 Sec Down Count
        sw_lap = 3'b111;
        sw_sel = 2'b10;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0100;
        #(20 * us_10);

        for (i = 0; i < 11; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #11 Hour Up Count
        sw_lap = 3'b111;
        sw_sel = 2'b11;
        {btn_L, btn_R, btn_U, btn_D} = 4'b1000;
        #(20 * us_10);

        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * us_10);

        {btn_L, btn_R, btn_U, btn_D} = 4'b1000;
        #(20 * us_10);

        for (i = 0; i < 2; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0010;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #12 Min Up Count
        sw_lap = 3'b111;
        sw_sel = 2'b11;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0100;
        #(20 * us_10);

        for (i = 0; i < 11; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0010;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #13 Sec Up Count
        sw_lap = 3'b111;
        sw_sel = 2'b10;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0100;
        #(20 * us_10);

        for (i = 0; i < 11; i = i + 1) begin
            {btn_L, btn_R, btn_U, btn_D} = 4'b0010;
            #(20 * us_10);

            {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
            #ms_10;
        end

        // #14 check msec, sec, display flicker
        sw_lap = 3'b111;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0001;
        #(20 * us_10);

        sw_lap = 3'b000;
        sw_sel = 2'b00;
        {btn_L, btn_R, btn_U, btn_D} = 4'b0000;
        #(20 * us_10);

        // #8 check min, hour, display flicker
        reset = 1;
        # ms_10
        $stop;
    end
endmodule
