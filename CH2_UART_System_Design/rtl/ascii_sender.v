`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ascii_sender
//  '1' : stopwatch mode      -> 가산 'p' / 감산 'm'
//  '2' : stopwatch run_stop  -> run  'R' / stop  'S'
//  '3' : watch  set_mode     -> 수정중 'Y' / 현재시각 'N'
//  '4' : SR04 distance       -> 거리 측정값 (3자리)
//  cmd[1] = '5' : DHT11 humidity      -> 습도 (2자리)
//  cmd[0] = '6' : DHT11 temperature   -> 온도 (2자리)

module ascii_sender (
    input            clk,
    input            rst,

    input      [5:0] cmd,

    // ── datapath 상태 (상시 유효) ──
    input            sw_mode,      // stopwatch : 0 = 가산, 1 = 감산
    input            sw_run,       // stopwatch : 1 = run,  0 = stop
    input            watch_set,    // watch     : 1 = 시간수정중, 0 = normal

    input      [8:0] distance,     // SR04  cm      (보류)
    input      [7:0] humidity,     // DHT11 습도 정수 (보류)
    input      [7:0] temperature,  // DHT11 온도 정수 (보류)

    // ── FIFO_TX ──
    output reg [7:0] tx_data,
    output reg       tx_push,
    input            tx_full
);

    localparam        IDLE = 1'b0, SEND = 1'b1;
    localparam [2:0]  LAST_IDX = 3'd6;      // 0, 1, 2, 3, 4, 5, 6 => 7 byte

    reg       state_reg, state_next;
    reg [2:0] idx_reg,   idx_next;

    reg [7:0] label_reg, label_next;
    reg [7:0] c2_reg,    c2_next;
    reg [7:0] c1_reg,    c1_next;
    reg [7:0] c0_reg,    c0_next;

    // 숫자 -> ASCII 변환

    reg  [9:0] val;
    always @(*) begin
        val = 10'd0;
        case (1'b1)
            cmd[2]:  val = {1'b0, distance};
            cmd[1]:  val = {2'b0, humidity};
            cmd[0]:  val = {2'b0, temperature};
            default: val = 10'd0;
        endcase
    end

    wire [3:0] dig2 = (val / 100) % 10;
    wire [3:0] dig1 = (val /  10) % 10;
    wire [3:0] dig0 =  val        % 10;

    //state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            idx_reg   <= 3'd0;
            label_reg <= 8'h20;
            c2_reg    <= 8'h20;
            c1_reg    <= 8'h20;
            c0_reg    <= 8'h20;
        end else begin
            state_reg <= state_next;
            idx_reg   <= idx_next;
            label_reg <= label_next;
            c2_reg    <= c2_next;
            c1_reg    <= c1_next;
            c0_reg    <= c0_next;
        end
    end

    //next state CL
    always @(*) begin
        state_next = state_reg;
        idx_next   = idx_reg;
        label_next = label_reg;
        c2_next    = c2_reg;
        c1_next    = c1_reg;
        c0_next    = c0_reg;

        case (state_reg)
            IDLE: begin
                idx_next = 3'd0;
                if (|cmd) begin
                    state_next = SEND;
                    if (cmd[5]) begin
                        label_next = "1";
                        c2_next    = " ";
                        c1_next    = " ";
                        c0_next    = sw_mode   ? "m" : "p";
                    end else if (cmd[4]) begin
                        label_next = "2";
                        c2_next    = " ";
                        c1_next    = " ";
                        c0_next    = sw_run    ? "R" : "S";
                    end else if (cmd[3]) begin
                        label_next = "3";
                        c2_next    = " ";
                        c1_next    = " ";
                        c0_next    = watch_set ? "Y" : "N";
                    end else if (cmd[2]) begin
                        label_next = "4";
                        c2_next    = "0" + dig2;
                        c1_next    = "0" + dig1;
                        c0_next    = "0" + dig0;
                    end else if (cmd[1]) begin
                        label_next = "5";
                        c2_next    = " ";
                        c1_next    = "0" + dig1;
                        c0_next    = "0" + dig0;
                    end else begin
                        label_next = "6";
                        c2_next    = " ";
                        c1_next    = "0" + dig1;
                        c0_next    = "0" + dig0;
                    end
                end
            end

            SEND: begin
                if (!tx_full) begin
                    if (idx_reg == LAST_IDX) begin
                        state_next = IDLE;
                        idx_next   = 3'd0;
                    end else begin
                        idx_next = idx_reg + 1'b1;
                    end
                end
            end
        endcase
    end


    // output CL 
    always @(*) begin
        tx_push = 1'b0;
        tx_data = 8'h00;
        if (state_reg == SEND) begin
            tx_push = ~tx_full;
            case (idx_reg)
                3'd0: tx_data = label_reg;
                3'd1: tx_data = ":";
                3'd2: tx_data = c2_reg;
                3'd3: tx_data = c1_reg;
                3'd4: tx_data = c0_reg;
                3'd5: tx_data = 8'h0D;   // CR
                3'd6: tx_data = 8'h0A;   // LF
                default: tx_data = 8'h20;
            endcase
        end
    end
endmodule
