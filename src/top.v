`timescale 1ns/1ps

module tick_1hz #(
  parameter integer CLK_HZ  = 100_000_000,
  parameter integer TICK_HZ = 1               // 1 Hz → 1 s period
)(
  input  wire clk,
  input  wire rst,         // active-high sync reset
  output reg  tick         // 1-cycle pulse every 1 s
);
  localparam integer DIV = CLK_HZ / TICK_HZ;  // 100_000_000
  // ceil(log2(100_000_000)) = 27
  reg [26:0] cnt = 0;

  always @(posedge clk) begin
    if (rst) begin
      cnt  <= 0;
      tick <= 1'b0;
    end else if (cnt == DIV-1) begin
      cnt  <= 0;
      tick <= 1'b1;        // assert for one 100 MHz cycle
    end else begin
      cnt  <= cnt + 1'b1;
      tick <= 1'b0;
    end
  end
endmodule


module top(
    input  wire       clk,
    output wire [7:0] leds
);
    localparam integer WIDTH = 32;
    localparam integer L     = 4;
    localparam integer N     = 7;

    // Power-on reset (holds 'rst' high ~16 cycles)
    reg [3:0] por = 0;
    wire rst = (por != 4'hF);
    always @(posedge clk) if (por != 4'hF) por <= por + 1'b1;
    
    // Sample ROM (2,3,4,5,6,7,8)
    function automatic signed [WIDTH-1:0] sample_rom (input [2:0] i);
        case (i)
            3'd0: sample_rom = 32'sd2;
            3'd1: sample_rom = 32'sd3;
            3'd2: sample_rom = 32'sd4;
            3'd3: sample_rom = 32'sd5;
            3'd4: sample_rom = 32'sd6;
            3'd5: sample_rom = 32'sd7;
            3'd6: sample_rom = 32'sd8;
            default: sample_rom = 32'sd0;
        endcase
    endfunction

    reg                      in_valid  = 0;
    reg  signed [WIDTH-1:0]  in_sample = 0;
    reg         [2:0]        idx       = 0;
    reg                      streaming = 0;

    wire tick1;
    tick_1hz u_tick(.clk(clk), .rst(rst), .tick(tick1));

    always @(posedge clk) begin
        if (rst) begin
            in_valid  <= 0;
            in_sample <= 0;
            idx       <= 0;
            streaming <= 0;
        end else begin
          in_valid <= 0;
		      if (tick1) begin	
            if (!streaming) begin
                streaming <= 1;          // start after reset
            end else if (idx < N) begin
                in_sample <= sample_rom(idx);
                in_valid  <= 1;          // valid for this clock
                idx       <= idx + 1;
            end else begin
            end
          end
        end
    end

    wire                     out_valid;
    wire signed [WIDTH-1:0]  out_avg;

    sliding_window #(
        .WIDTH(WIDTH),
        .L(L)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .in_valid  (in_valid),
        .in_sample (in_sample),
        .out_valid (out_valid),
        .out_avg   (out_avg)
    );

    
    assign leds = out_avg[7:0];
endmodule

