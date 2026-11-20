`timescale 1ns / 1ps
module fifo #(
    parameter ADDRWIDTH = 4
) (
    input clk,
    input reset,
    input push,
    input pop,
    input [7:0] wdata,  // push data
    output [7:0] rdata,  // pop data, output
    output full,
    output empty
);

    wire [ADDRWIDTH-1:0] w_wptr, w_rptr;


    register_file U_REG_FILE (
        .clk(clk),
        .waddr(w_wptr),
        .raddr(w_rptr),
        .wdata(wdata),
        .we(~full & push),
        .rdata(rdata)  //output
    );


    control_unit U_CONTROL_UNIT (
        .clk  (clk),
        .reset(reset),
        .push (push),
        .pop  (pop),
        .wptr (w_wptr),  //output
        .rptr (w_rptr),
        .full (full),
        .empty(empty)
    );

endmodule

module register_file #(
    parameter ADDRWIDTH = 4
) (
    input clk,
    input [ADDRWIDTH-1:0] waddr,
    input [ADDRWIDTH-1:0] raddr,
    input [7:0] wdata,
    input we,
    output [7:0] rdata  //output
);

    parameter DEPTH = 2 ** ADDRWIDTH;  //DEPTH = 4, ADDRWIDTH =2
    reg [7:0] register_file[0:DEPTH-1];  //8bit 4blocks

    always @(posedge clk) begin
        if (we) register_file[waddr] <= wdata;
    end

    //output : rdata CL output
    assign rdata = register_file[raddr];

endmodule


module control_unit #(
    parameter ADDRWIDTH = 4
) (
    input clk,
    input reset,
    input push,
    input pop,
    output [ADDRWIDTH-1:0] wptr,  //output
    output [ADDRWIDTH-1:0] rptr,
    output full,
    output empty
);

    reg [ADDRWIDTH-1:0] wptr_next, wptr_reg;
    reg [ADDRWIDTH-1:0] rptr_next, rptr_reg;
    reg empty_reg, empty_next, full_reg, full_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wptr_reg  <= 0;
            rptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            empty_reg <= empty_next;
            full_reg  <= full_next;
        end
    end

    //next CL
    always @(*) begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        case ({
            push, pop
        })
            2'b00: begin
                //init
            end
            2'b01: begin
                //pop
                if (!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 1'b0;
                    if (rptr_next == wptr_reg) empty_next = 1'b1;
                end
            end
            2'b10: begin
                //push only
                if (!full_reg) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 0;
                    if (wptr_next == rptr_reg) full_next = 1;
                end
            end
            2'b11: begin
                //push_pop
                if (full) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                end else if (empty) begin
                    wptr_next  = wptr_reg + 1;
                    empty_next = 1'b0;
                end else begin
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
        endcase
    end
endmodule
