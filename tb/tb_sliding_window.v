`timescale 1ns / 1ps

module tb_sliding_window;
    localparam integer WIDTH = 32;
    localparam integer L     = 8;
    // localparam integer L     = 4;
    localparam integer N     = 4096;   // number of samples in mat input file

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;  // 100 MHz clock

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

    reg signed [WIDTH-1:0] rom [0:N-1]; // rom loaded from input mem file

    initial begin
        $readmemh("./tb/input_data.mem", rom);

        // Waveform dump
        if (!$test$plusargs("NOVCD")) begin
            $dumpfile("build/wave.vcd");
            $dumpvars(0, tb_sliding_window);
        end
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

    integer i;
    initial begin
        // Open output text to save
        fh = $fopen("./tb_large_output.txt", "w");
        
        if (fh == 0) begin
            $display("ERROR: Could not open tb_large_output.txt");
            $finish;
        end

        // Reset
        repeat (4) @(negedge clk);
        rst <= 1'b0;

        // Stream all samples with the task
        for (i = 0; i < N; i = i + 1) begin
            drive_sample(rom[i]);
        end

        repeat (3) @(negedge clk);

        $fclose(fh);
        $display("DONE: wrote tb_large_output.txt");
        $finish;
    end
    
    // log and store outputs
    always @(posedge clk) begin
        if (out_valid) begin
            $fwrite(fh, "Input: %032b | Output: %032b\n", in_sample, out_avg);
            $display("%0t ns  in=%0d  out=%0d", $time, in_sample, out_avg);
        end
    end
endmodule
