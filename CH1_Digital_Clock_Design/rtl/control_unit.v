`timescale 1ns / 1ps
module watch_control_unit (
    input  clk,
    input  reset,
    input  i_change_L,
    input  i_change_R,
    input  i_change_U,
    input  i_change_D,
    input  uart_change_L,
    input  uart_change_R,
    input  uart_change_U,
    input  uart_change_D,
    output o_hour_sel,
    output o_min_sel,
    output o_sec_sel,
    output o_up_count,
    output o_down_count
);

    // state parameter
    parameter NORMAL = 3'b000, HOUR = 3'b001, MIN = 3'b010, SEC = 3'b011, UP = 3'b100, DOWN = 3'b101;

    // register
    reg [2:0] n_state, c_state;
    reg hour_sel_next, hour_sel_reg;
    reg min_sel_next, min_sel_reg;
    reg sec_sel_next, sec_sel_reg;
    reg up_count_next, up_count_reg;
    reg down_count_next, down_count_reg;

    // OR
    wire change_L, change_R, change_U, change_D;
    assign change_L = i_change_L | uart_change_L;
    assign change_R = i_change_R | uart_change_R;
    assign change_U = i_change_U | uart_change_U;
    assign change_D = i_change_D | uart_change_D;


    // output assign
    assign o_hour_sel = hour_sel_reg;
    assign o_min_sel = min_sel_reg;
    assign o_sec_sel = sec_sel_reg;
    assign o_up_count = up_count_reg;
    assign o_down_count = down_count_reg;

    // CL 
    always @(*) begin
        n_state = c_state;
        hour_sel_next   = hour_sel_reg;
        min_sel_next    = min_sel_reg;
        sec_sel_next    = sec_sel_reg;
        up_count_next   = up_count_reg;
        down_count_next = down_count_reg;
        case (c_state)
            NORMAL: begin
                hour_sel_next   = 1'b0;
                min_sel_next    = 1'b0;
                sec_sel_next    = 1'b0;
                up_count_next   = 1'b0;
                down_count_next = 1'b0;
                if (change_R) n_state = HOUR;
                else if (change_L) n_state = SEC;
            end
            HOUR: begin
                hour_sel_next   = 1'b1;
                min_sel_next    = 1'b0;
                sec_sel_next    = 1'b0;
                up_count_next   = 1'b0;
                down_count_next = 1'b0;
                if (change_R) n_state = MIN;
                else if (change_L) n_state = NORMAL;
                else if (change_U) n_state = UP;
                else if (change_D) n_state = DOWN;
            end
            MIN: begin
                hour_sel_next   = 1'b0;
                min_sel_next    = 1'b1;
                sec_sel_next    = 1'b0;
                up_count_next   = 1'b0;
                down_count_next = 1'b0;
                if (change_R) n_state = SEC;
                else if (change_L) n_state = HOUR;
                else if (change_U) n_state = UP;
                else if (change_D) n_state = DOWN;
            end
            SEC: begin
                hour_sel_next   = 1'b0;
                min_sel_next    = 1'b0;
                sec_sel_next    = 1'b1;
                up_count_next   = 1'b0;
                down_count_next = 1'b0;
                if (change_R) n_state = NORMAL;
                else if (change_L) n_state = MIN;
                else if (change_U) n_state = UP;
                else if (change_D) n_state = DOWN;
            end
            UP: begin
                up_count_next = 1'b1;
                if (hour_sel_reg) n_state = HOUR;
                else if (min_sel_reg) n_state = MIN;
                else if (sec_sel_reg) n_state = SEC;
            end
            DOWN: begin
                down_count_next = 1'b1;
                if (hour_sel_reg) n_state = HOUR;
                else if (min_sel_reg) n_state = MIN;
                else if (sec_sel_reg) n_state = SEC;
            end
        endcase
    end

    // SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= NORMAL;
            hour_sel_reg <= 0;
            min_sel_reg <= 0;
            sec_sel_reg <= 0;
            up_count_reg <= 0;
            down_count_reg <= 0;
        end else begin
            c_state <= n_state;
            hour_sel_reg <= hour_sel_next;
            min_sel_reg <= min_sel_next;
            sec_sel_reg <= sec_sel_next;
            up_count_reg <= up_count_next;
            down_count_reg <= down_count_next;
        end
    end
endmodule

module stopwatch_control_unit (
    input  clk,
    input  reset,
    input  i_run,
    input  i_stop,
    input  i_clear,
    input  i_mode,
    input  i_lap,
    input  uart_run,
    input  uart_stop,
    input  uart_clear,
    input  uart_mode,
    input  uart_lap,
    output o_run_stop,
    output o_clear,
    output o_mode,
    output o_lap
);

    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, MODE = 3'b011, LAP = 3'b100;
    reg [2:0] current_state, next_state;

    // register
    reg run_stop_reg, run_stop_next;
    reg clear_reg, clear_next;
    reg mode_reg, mode_next;
    reg lap_reg, lap_next;

    // OR
    wire run, stop, clear, mode, lap;
    assign run = i_run | uart_run;
    assign stop = i_stop | uart_stop;
    assign clear = i_clear | uart_clear;
    assign mode = i_mode | uart_mode;
    assign lap = i_lap | uart_lap;


    // assignment
    assign o_run_stop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;
    assign o_lap = lap_reg;

    // CL
    always @(*) begin
        next_state = current_state;
        run_stop_next = run_stop_reg;
        clear_next = clear_reg;
        mode_next = mode_reg;
        lap_next = lap_reg;
        case (current_state)
            STOP: begin
                run_stop_next = 1'b0;
                clear_next = 1'b0;
                lap_next = 1'b0;
                if(run) begin // if state has priority, run should run first if run and clear are pressed at the same time
                    next_state = RUN;
                end else if (clear) begin
                    next_state = CLEAR;
                end else if (mode) begin
                    next_state = MODE;
                end
            end

            RUN: begin
                run_stop_next = 1'b1;
                lap_next = 1'b0;
                if (stop) begin
                    next_state = STOP;
                end else if (lap) begin
                    next_state = LAP;
                end
            end

            CLEAR: begin
                next_state = STOP;
                clear_next = 1'b1;
            end

            MODE: begin
                next_state = STOP;
                mode_next  = ~mode_reg;
            end

            LAP: begin
                next_state = RUN;
                lap_next   = 1'b1;
            end
        endcase
    end

    // SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= STOP;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
            lap_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
            lap_reg <= lap_next;
        end
    end
endmodule
