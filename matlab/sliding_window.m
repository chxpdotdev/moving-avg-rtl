clear; clc; close all;

set(0, "defaultfigurevisible", "off");    % no windows
graphics_toolkit("qt");                   % go headless

% Variables
WINDOW_LENGTH = 8;
WINDOW_LENGTH_4 = 4;
BIT_WIDTH = 32;
OUTFILE = 'tb_large_output_matlab.txt';

% Import data
load("input.mat", 'sample_data');

% ----------- Save as .mem file ------------ %

% two's complement bit pattern
i32_sample_data = int32(int16(sample_data(:))); 
u32_sample_data = typecast(i32_sample_data, 'uint32');

fid = fopen('input_data.mem','w');

for k = 1:numel(u32_sample_data)
    % 8 hex digits per line
    fprintf(fid, '%08X\n', u32_sample_data(k));
end

fclose(fid);

% ------------------------------------------ %

% Performs sliding window (moving avg) recursively
function y = sliding_window(x, L)
    x = x(:);
    N = numel(x);
    y = zeros(N, 1);
    y(1) = x(1) / L;

    for n = 2 : N
        x_n_L = 0;
        if n - L >= 1, x_n_L = x(n - L); end
        y(n) = y(n - 1) + (x(n) - x_n_L) / L;
    end
end

x = double(sample_data(:));
N = numel(x);

y = sliding_window(x, WINDOW_LENGTH);
y_wl_4 = sliding_window(x, WINDOW_LENGTH_4);

fig = figure('Name','Sliding Window', 'color','none');   % transparent figure
ax  = axes('Parent', fig, 'color','none', 'Box','off');  % transparent axes
hold(ax, 'on');

plot(ax, x,          'DisplayName','Sample data');
plot(ax, y,          'LineStyle','-',  'DisplayName','L = 8');
plot(ax, y_wl_4,     'LineStyle','--', 'DisplayName','L = 4');

grid(ax, 'off');                                        % no grid
legend(ax, 'Location','best', 'Box','off');             % clean legend
xlabel(ax, 'n'); ylabel(ax, 'Amplitude');
title(ax, 'Original sample data and sliding window');
print(fig, "-dsvg", "plot.svg");


% ----------- Save as output file ------------ %
% this is to save as an output file to compare with the verilog output file

x_integer = floor(x);
y_integer = floor(y); % FLOOR NOT ROUND

fid = fopen(OUTFILE,'w');

in_i32  = int32(int16(sample_data(:)));
out_i32 = int32(y_integer);

for n = 1:N
    in_u32  = typecast(in_i32(n),  'uint32');
    out_u32 = typecast(out_i32(n), 'uint32');
    fprintf(fid, 'Input: %s | Output: %s\n', ...
        dec2bin(double(in_u32),  BIT_WIDTH), ...
        dec2bin(double(out_u32), BIT_WIDTH));
end

fclose(fid);
