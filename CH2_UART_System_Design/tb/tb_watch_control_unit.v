`timescale 1ns / 1ps

module tb_watch_control_unit ();
    reg clk, reset;
    reg i_change_L, i_change_R, i_change_U, i_change_D;
    reg uart_change_L, uart_change_R, uart_change_U, uart_change_D;
    wire o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count;

    watch_control_unit dut (
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

    // Clock generation
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

        // Reset
        #10 reset = 0;
        #10 $display("=== Test 1: Initial State (NORMAL) ===");
        $display("Time: %0t | State: NORMAL | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 1: NORMAL -> HOUR (press right)
        #10 i_change_R = 1;
        #10 i_change_R = 0;
        #10 $display("\n=== Test 2: NORMAL -> HOUR (via change_R) ===");
        $display("Time: %0t | State: HOUR | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 2: HOUR -> MIN (press right)
        #10 i_change_R = 1;
        #10 i_change_R = 0;
        #10 $display("\n=== Test 3: HOUR -> MIN (via change_R) ===");
        $display("Time: %0t | State: MIN | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 3: MIN -> SEC (press right)
        #10 i_change_R = 1;
        #10 i_change_R = 0;
        #10 $display("\n=== Test 4: MIN -> SEC (via change_R) ===");
        $display("Time: %0t | State: SEC | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 4: SEC -> NORMAL (press right)
        #10 i_change_R = 1;
        #10 i_change_R = 0;
        #10 $display("\n=== Test 5: SEC -> NORMAL (via change_R) ===");
        $display("Time: %0t | State: NORMAL | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 5: NORMAL -> SEC (press left)
        #10 i_change_L = 1;
        #10 i_change_L = 0;
        #10 $display("\n=== Test 6: NORMAL -> SEC (via change_L) ===");
        $display("Time: %0t | State: SEC | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 6: SEC -> MIN (press left)
        #10 i_change_L = 1;
        #10 i_change_L = 0;
        #10 $display("\n=== Test 7: SEC -> MIN (via change_L) ===");
        $display("Time: %0t | State: MIN | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 7: MIN -> UP (press up) and check if up_count is set
        #10 i_change_U = 1;
        #10 i_change_U = 0;
        #10 $display("\n=== Test 8: MIN -> UP (via change_U) ===");
        $display("Time: %0t | State: UP | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 8: UP -> MIN (stays with min_sel_reg)
        #10 $display("\n=== Test 9: UP -> MIN (back to MIN) ===");
        $display("Time: %0t | State: MIN | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 9: Move to HOUR and test DOWN
        #10 i_change_L = 1;
        #10 i_change_L = 0;
        #10 i_change_R = 1;
        #10 i_change_R = 0;
        #10 $display("\n=== Test 10: Move to HOUR state ===");
        $display("Time: %0t | State: HOUR | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 10: HOUR -> DOWN (press down)
        #10 i_change_D = 1;
        #10 i_change_D = 0;
        #10 $display("\n=== Test 11: HOUR -> DOWN (via change_D) ===");
        $display("Time: %0t | State: DOWN | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 11: DOWN -> HOUR (back to HOUR)
        #10 $display("\n=== Test 12: DOWN -> HOUR (back to HOUR) ===");
        $display("Time: %0t | State: HOUR | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 12: Test UART input (OR gate)
        #10 uart_change_R = 1;
        #10 uart_change_R = 0;
        #10 $display("\n=== Test 13: HOUR -> MIN (via uart_change_R) ===");
        $display("Time: %0t | State: MIN | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Scenario 13: Test combined input (uart + button)
        #10 i_change_R = 1;
        uart_change_R = 1;
        #10 i_change_R = 0;
        uart_change_R = 0;
        #10 $display("\n=== Test 14: MIN -> SEC (via both i_change_R and uart_change_R) ===");
        $display("Time: %0t | State: SEC | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        // Test reset during operation
        #10 $display("\n=== Test 15: Reset during SEC state ===");
        reset = 1;
        #10 reset = 0;
        #10 $display("Time: %0t | State: NORMAL (after reset) | hour_sel=%b, min_sel=%b, sec_sel=%b, up=%b, down=%b", 
                 $time, o_hour_sel, o_min_sel, o_sec_sel, o_up_count, o_down_count);

        #20 $finish;
    end

endmodule
