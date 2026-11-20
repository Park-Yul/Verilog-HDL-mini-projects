`timescale 1ns / 1ps
module sr04_controller (
    input clk,
    input reset,
    input start,
    input echo,
    output trigger,
    output busy,
    output done,
    output [8:0] distance
);

    // wire
    wire w_tick_us;

    // tick_us instantiation
    tick_us U_TICK_US (
        .i_clk       (clk),
        .i_reset     (reset),
        .o_tick    (w_tick_us)
    );

    // tick_us instantiation
    fsm_sr04 U_FSM_SR04 (
        .clk     (clk),
        .reset   (reset),
        .start   (start),
        .echo    (echo),
        .tick    (w_tick_us),
        .trigger (trigger),
        .busy    (busy),
        .done    (done),
        .distance(distance)     // 2cm ~ 400cm
    );



endmodule

//////////

module tick_us (
    input  i_clk,
    input  i_reset,
    output o_tick
);
    parameter F_COUNT = 100;  // f = 1MHz, T = 1us
    reg tick_reg;
    assign o_tick = tick_reg;

    reg [$clog2(F_COUNT)-1:0] counter_reg;
    always @(posedge i_clk, posedge i_reset) begin
        if (i_reset) begin
            counter_reg <= 0;
            tick_reg    <= 0;
        end else if (counter_reg == (F_COUNT - 1)) begin
            counter_reg <= 0;
            tick_reg    <= 1;
        end else begin
            counter_reg <= counter_reg + 1;
            tick_reg    <= 0;
        end
    end
endmodule

//////////

module fsm_sr04 (
    input clk,
    input reset,
    input start,
    input echo,
    input tick,
    output trigger,
    output busy,
    output done,
    output [8:0] distance  // 2cm ~ 400cm
);

    // state parameter
    parameter IDLE = 3'b000;
    parameter TRIGGER = 3'b001;
    parameter WAIT = 3'b010;
    parameter ECHO = 3'b011;
    parameter DIST = 3'b100;

    // register
    reg [2:0] n_state, c_state;
    reg trigger_next, trigger_reg;
    reg busy_next, busy_reg;
    reg done_next, done_reg;
    reg [15:0] tick_count_next, tick_count_reg;
    reg [5:0] dist_count_next, dist_count_reg;
    reg [8:0] dist_next, dist_reg;

    // assignment

    assign trigger  = trigger_reg;
    assign busy       = busy_reg;
    assign done       = done_reg;
    assign distance   = dist_reg;

    // CL
    always @(*) begin
        n_state         = c_state;
        trigger_next    = trigger_reg;
        busy_next       = busy_reg;
        done_next       = done_reg;
        tick_count_next = tick_count_reg;
        dist_count_next = dist_count_reg;
        dist_next       = dist_reg;
        case (c_state)
            IDLE: begin
                done_next     = 0;
                if (start) begin
                    n_state         = TRIGGER;
                    trigger_next    = 1;
                    busy_next       = 1;
                    tick_count_next = 0;
                end
            end
            TRIGGER: begin
                if (tick) begin
                    if (tick_count_reg >= 10) begin
                        n_state = WAIT;
                        tick_count_next = 0;
                        trigger_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            WAIT: begin
                if(tick)begin
                    if (echo) begin
                        n_state = ECHO;
                    end
                end
            end
            ECHO: begin
                if (tick) begin
                    if (echo) begin
                        tick_count_next = tick_count_reg + 1;
                    end else begin
                        n_state = DIST;
                        dist_count_next = 0;
                        dist_next = 1;
                    end
                end
            end
            DIST: begin
                if (tick_count_reg >= 35_000 - 1) begin
                    n_state   = IDLE;
                    dist_next = 400;
                    busy_next = 0;
                    done_next = 0;
                end
                else 
                if (tick_count_reg == 0) begin
                    n_state   = IDLE;
                    busy_next = 0;
                    done_next = 1;
                end else begin
                    tick_count_next = tick_count_reg - 1;
                    if (dist_count_reg == 58 - 1) begin
                        dist_count_next = 0;
                        dist_next = dist_reg + 1;
                    end else begin
                        dist_count_next = dist_count_reg + 1;
                    end
                end
            end
        endcase
    end

    // SL
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state        <= IDLE;
            trigger_reg    <= 0;
            busy_reg       <= 0;
            done_reg       <= 0;
            tick_count_reg <= 0;
            dist_count_reg <= 0;
            dist_reg       <= 1;
        end else begin
            c_state        <= n_state;
            trigger_reg    <= trigger_next;
            busy_reg       <= busy_next;
            done_reg       <= done_next;
            tick_count_reg <= tick_count_next;
            dist_count_reg <= dist_count_next;
            dist_reg       <= dist_next;
        end
    end

 //   // ILA
 //   ila_0 U_ILA_0 (
 //       .clk(clk),
 //       .probe0(start),  // start
 //       .probe1(trigger),  // trigger
 //       .probe2(echo),  // echo
 //       .probe3(c_state)  // c_state
 //   );


endmodule

/////////

module sr04_control_unit #(
    parameter F_COUNT = 10_000_000
) (
    input  i_clk,
    input  i_reset,
    output o_tick_1s
);

    // reg
    reg [$clog2(F_COUNT) - 1 : 0] counter_reg;
    reg tick_1s_reg;

    // CL
    assign o_tick_1s = tick_1s_reg;

    // SL
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            counter_reg <= 0;
            tick_1s_reg <= 0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_1s_reg <= 1;
            end else begin
                counter_reg <= counter_reg + 1;
                tick_1s_reg <= 0;
            end
        end
    end
endmodule
