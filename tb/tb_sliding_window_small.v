`timescale 1ns/1ps

module tb_sliding_window_small;
    localparam integer WIDTH = 32;
    localparam integer L     = 4;

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;   // 100 MHz

    reg                      in_valid = 0;
    reg  signed [WIDTH-1:0]  in_sample = 0;
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

    // Waveform dump
    initial begin
      if (!$test$plusargs("NOVCD")) begin
        $dumpfile("build/wave.vcd");               // make sure 'build/' exists
        $dumpvars(0, tb_sliding_window_small);     // dump whole TB hierarchy
      end
    end

    // Small sample data: 2,3,4,5,6,7,8
    localparam integer N = 7;
    reg signed [WIDTH-1:0] samples [0:N-1];

    initial begin
        samples[0] = 32'sd2;
        samples[1] = 32'sd3;
        samples[2] = 32'sd4;
        samples[3] = 32'sd5;
        samples[4] = 32'sd6;
        samples[5] = 32'sd7;
        samples[6] = 32'sd8;
    end

    integer fh; // output file

    // task to do one sample in one clock
    task drive_sample(input signed [WIDTH-1:0] s);
    begin
        @(negedge clk);
        in_sample <= s;
        in_valid  <= 1'b1;
        @(negedge clk);
        in_valid  <= 1'b0;
    end
    endtask

    // Test sequence
    integer i;
    initial begin
        // Open the output file
        fh = $fopen("./tb_small_output.txt", "w");
        if (fh == 0) begin
            $display("ERROR: could not open output file");
            $finish;
        end

        // Reset
        repeat (4) @(negedge clk);
        rst <= 1'b0;

        // Stream all samples with the task
        for (i = 0; i < N; i = i + 1) begin
            drive_sample(samples[i]);
        end
        
        repeat (3) @(negedge clk);

        $fclose(fh);
        $display("DONE: wrote tb_small_output.txt");
        $finish;
    end
    
    // log and store outputs
    always @(posedge clk) begin
        if (out_valid) begin
            $fwrite(fh, "Input: %032b | Output: %032b\n", in_sample, out_avg);
            $display("%0t ns  in=%0d  out=%0d  (in=%032b | out=%032b)",
                     $time, in_sample, out_avg, in_sample, out_avg);
        end
    end
endmodule

