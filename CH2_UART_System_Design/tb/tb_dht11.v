`timescale 1ns / 1ps
module tb_dht11_contol_unit;
    reg  i_clk;
    reg  i_reset;
    wire o_tick_1s;


    dht11_control_unit DUT (
        .i_clk    (i_clk),
        .i_reset  (i_reset),
        .o_tick_1s(o_tick_1s)
    );

    // clock generation
    always #5 i_clk = ~i_clk ;

    // scenario
    initial begin
        i_clk = 0;
        i_reset = 1;

        @(negedge i_clk)
        i_reset = 0;    

        // start
        @(posedge o_tick_1s)
        # 100;
        $stop;
    
    end

endmodule
