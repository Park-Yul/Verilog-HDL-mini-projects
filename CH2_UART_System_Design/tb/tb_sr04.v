`timescale 1ns / 1ps
module tb_top_sr04;
    reg clk;
    reg reset;
    reg start;
    reg echo;
    wire trigger;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;

    // DUT Instantiation
    top_sr04 DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .echo(echo),
        .trigger(trigger),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    // reg for random test
    reg [8:0] distance_setting;

    // integer
    integer i = 0;
    integer pass_cnt = 0, fail_cnt = 0;

    // clock generation
    always #5 clk = ~clk;

    // scenario
    initial begin
        clk   = 0;
        reset = 1;
        #10;

        reset = 0;
        for (i = 0; i < 20; i = i + 1) begin
            // start
            @(posedge clk) #1;
            start = 1;
            #200_000;

            // trigger negedge wait
            @(posedge clk) #1;
            start = 0;

            // sonic burst
            #200_000;  // 200us

            // echo
            @(posedge clk) #1;
            echo = 1;
            distance_setting = ($random % 500) + 2;
            if (distance_setting <= 400) #(distance_setting * 58 * 1_000);
            else #36_000_000;  // 36ms
            echo = 0;

            // dist calculation
            #1_000_000;  // 1ms wait
            if (DUT.w_distance == distance_setting) begin
                $strobe("%t : PASS!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, DUT.w_distance);
                pass_cnt = pass_cnt + 1;
            end else if (distance_setting > 400) begin
                if (DUT.w_distance == 400) begin
                    $strobe(
                        "%t : PASS!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, DUT.w_distance);
                    pass_cnt = pass_cnt + 1;
                end
            end else begin
                $strobe("%t : FAIL!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, DUT.w_distance);
                fail_cnt = fail_cnt + 1;
            end
        end
        #100;
        $display("%t : pass = %d, fail = %d", $time, pass_cnt, fail_cnt);
        $stop;
    end


endmodule


module tb_sr04_controller;
    reg clk;
    reg reset;
    reg start;
    reg echo;
    wire trigger;
    wire busy;
    wire done;
    wire [8:0] distance;

    // reg for random test
    reg [8:0] distance_setting;

    // integer
    integer i = 0;
    integer pass_cnt = 0, fail_cnt = 0;

    // DUT instantiation
    sr04_controller DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .echo(echo),
        .trigger(trigger),
        .busy(busy),
        .done(done),
        .distance(distance)
    );

    // clock generation
    always #5 clk = ~clk;

    // scenario
    initial begin
        clk   = 0;
        reset = 1;
        #10;

        reset = 0;
        for (i = 0; i < 20; i = i + 1) begin
            // start
            @(posedge clk) #1;
            start = 1;

            // trigger negedge wait
            @(posedge clk) #1;
            start = 0;

            @(negedge trigger);

            // sonic burst
            #200_000;  // 200us

            // echo
            @(posedge clk) #1;
            echo = 1;
            distance_setting = ($random % 500) + 2;
            if (distance_setting <= 400) #(distance_setting * 58 * 1_000);
            else #36_000_000;  // 36ms
            echo = 0;

            // dist calculation
            #1_000_000;  // 1ms wait
            if (distance == distance_setting) begin
                $strobe("%t : PASS!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, distance);
                pass_cnt = pass_cnt + 1;
            end else if (distance_setting > 400) begin
                if (distance == 400) begin
                    $strobe(
                        "%t : PASS!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, distance);
                    pass_cnt = pass_cnt + 1;
                end
            end else begin
                $strobe("%t : FAIL!!, distance_setting = %d cm, distance = %d",
                        $time, distance_setting, distance);
                fail_cnt = fail_cnt + 1;
            end
        end
        #100;
        $display("%t : pass = %d, fail = %d", $time, pass_cnt, fail_cnt);
        $stop;
    end

endmodule
