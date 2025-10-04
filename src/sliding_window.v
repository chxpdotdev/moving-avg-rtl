`timescale 1ns / 1ps


module sliding_window #(
    parameter integer WIDTH = 32,
    parameter integer L     = 8
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    in_valid,
    input  wire signed [WIDTH-1:0] in_sample,
    
    output reg                     out_valid,
    output reg signed [WIDTH-1:0]  out_avg
);

    // clog2 helper function 
    function integer clog2; 
        input integer value; 
        integer i; 
        begin 
            clog2 = 0; 
            for (i = value-1; i > 0; i = i >> 1) 
                clog2 = clog2 + 1; 
        end 
    endfunction
    
    localparam integer SHIFT = clog2(L);        // 3 as L = 8
    localparam integer SUMW  = WIDTH + SHIFT;   // Padding to hold the sum of L samples
    
    reg signed [WIDTH-1:0] buff [0:L-1];        // Circular buffer to remember last L samples
    reg [SHIFT-1:0]        wr_ptr;
    
    reg [SHIFT:0]          count;               // Count samples
    
    reg  signed [SUMW:0]    sum;
    wire signed [WIDTH-1:0] oldest = (count == L) ? buff[wr_ptr] : 0;
    
    wire signed [SUMW:0]    sum_next = sum + in_sample - oldest;
    
    wire signed [SUMW:0]    avg_ext = sum_next >>> SHIFT;   // arithmetic divide by L
    wire signed [WIDTH-1:0] avg_nxt = avg_ext[WIDTH-1:0];
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 0;
            out_avg   <= 0;
            wr_ptr    <= 0;
            count     <= 0;
            sum       <= 0;
            
            for (i = 0; i < L; i = i + 1) buff[i] <= 0;
            
        end else begin
            out_valid <= in_valid;
            
            if (in_valid) begin
                buff[wr_ptr] <= in_sample;
                wr_ptr       <= wr_ptr + 1;
                
                if (count != L) count <= count + 1;
                
                sum     <= sum_next;
                out_avg <= avg_nxt;
            end
        end
    end
endmodule