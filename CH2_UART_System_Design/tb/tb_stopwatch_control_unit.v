`timescale 1ns / 1ps

module tb_stopwatch_control_unit ();
    reg clk, reset;
    reg i_run, i_stop, i_clear, i_mode, i_lap;
    reg uart_run, uart_stop, uart_clear, uart_mode, uart_lap;
    wire o_run_stop, o_clear, o_mode, o_lap;

    stopwatch_control_unit dut (
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

    // Clock generation
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

        // Reset
        #10 reset = 0;
        #10 $display("=== Test 1: Initial State (STOP) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 1: STOP -> RUN (press run)
        #10 i_run = 1;
        #10 i_run = 0;
        #10 $display("\n=== Test 2: STOP -> RUN (via i_run) ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 2: RUN -> LAP (press lap)
        #10 i_lap = 1;
        #10 i_lap = 0;
        #10 $display("\n=== Test 3: RUN -> LAP (via i_lap) ===");
        $display("Time: %0t | State: LAP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 3: LAP -> RUN (return to run)
        #10 $display("\n=== Test 4: LAP -> RUN (back to RUN) ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 4: RUN -> STOP (press stop)
        #10 i_stop = 1;
        #10 i_stop = 0;
        #10 $display("\n=== Test 5: RUN -> STOP (via i_stop) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 5: STOP -> CLEAR (press clear)
        #10 i_clear = 1;
        #10 i_clear = 0;
        #10 $display("\n=== Test 6: STOP -> CLEAR (via i_clear) ===");
        $display("Time: %0t | State: CLEAR | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 6: CLEAR -> STOP (return to stop)
        #10 $display("\n=== Test 7: CLEAR -> STOP (back to STOP) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 7: STOP -> MODE (press mode)
        #10 i_mode = 1;
        #10 i_mode = 0;
        #10 $display("\n=== Test 8: STOP -> MODE (via i_mode) ===");
        $display("Time: %0t | State: MODE | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 8: MODE -> STOP (return to stop)
        #10 $display("\n=== Test 9: MODE -> STOP (back to STOP) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 9: Complete workflow - RUN -> LAP -> RUN -> STOP -> CLEAR
        #10 i_run = 1;
        #10 i_run = 0;
        #10 $display("\n=== Test 10a: RUN state ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 i_lap = 1;
        #10 i_lap = 0;
        #10 $display("=== Test 10b: LAP state ===");
        $display("Time: %0t | State: LAP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 $display("=== Test 10c: Back to RUN from LAP ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 i_stop = 1;
        #10 i_stop = 0;
        #10 $display("=== Test 10d: STOP state ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 i_clear = 1;
        #10 i_clear = 0;
        #10 $display("=== Test 10e: CLEAR state ===");
        $display("Time: %0t | State: CLEAR | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 10: Test UART input (OR gate)
        #10 $display("\n=== Test 11: STOP state (via back to STOP from CLEAR) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 uart_run = 1;
        #10 uart_run = 0;
        #10 $display("\n=== Test 12: STOP -> RUN (via uart_run) ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 11: Test combined input (uart + button)
        #10 i_stop = 1;
        uart_stop = 1;
        #10 i_stop = 0;
        uart_stop = 0;
        #10 $display("\n=== Test 13: RUN -> STOP (via both i_stop and uart_stop) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Scenario 12: Test mode toggle (mode is toggled in MODE state)
        #10 i_mode = 1;
        #10 i_mode = 0;
        #10 $display("\n=== Test 14: STOP -> MODE (1st time) ===");
        $display("Time: %0t | State: MODE | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 $display("=== Test 15: MODE -> STOP (mode should be toggled) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b (toggled), lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 i_mode = 1;
        #10 i_mode = 0;
        #10 $display("\n=== Test 16: STOP -> MODE (2nd time) ===");
        $display("Time: %0t | State: MODE | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 $display("=== Test 17: MODE -> STOP (mode should be toggled again) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b (toggled), lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Test reset during operation
        #10 i_run = 1;
        #10 i_run = 0;
        #10 $display("\n=== Test 18: RUN state before reset ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 $display("\n=== Test 19: Reset during RUN state ===");
        reset = 1;
        #10 reset = 0;
        #10 $display("Time: %0t | State: STOP (after reset) | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        // Edge case: Multiple inputs at same time (only first one should have priority based on if-else)
        #10 i_run = 1;
        #10 i_run = 0;
        #10 $display("\n=== Test 20: RUN state ===");
        $display("Time: %0t | State: RUN | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #10 i_stop = 1;
        i_lap = 1;
        #10 i_stop = 0;
        i_lap = 0;
        #10 $display("\n=== Test 21: Both i_stop and i_lap pressed (i_stop should take priority) ===");
        $display("Time: %0t | State: STOP | run_stop=%b, clear=%b, mode=%b, lap=%b", 
                 $time, o_run_stop, o_clear, o_mode, o_lap);

        #20 $finish;
    end

endmodule
