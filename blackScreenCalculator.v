module blackScreenCalculator(colorIn, enableLoad, xOut, yOut, clk, resetLow, colorOut, signalClearFinish);

	input enableLoad;
	input clk;
	input resetLow;
	input [2:0] colorIn;
	
	output reg [7:0] xOut;
	output reg [6:0] yOut;
	output reg [2:0] colorOut;
	output reg signalClearFinish;
	
	reg [7:0] x;
	initial x = 8'd0;
	reg [6:0] y;
	initial y = 7'd0;
	reg [7:0] count_x;
	reg [6:0] count_y;
	
	always @(posedge clk)
	begin
		if (resetLow == 1'b0)
		begin
			x <= 8'd0;
			y <= 7'd0;
		end
		// Load in x and y (should be 0) and reset the count for plotting (pixel counting)
		else if (enableLoad == 1'b1)
		begin
			xOut <= x;
			yOut <= y;
			count_x <= 8'd0;
			count_y <= 7'd0;
			signalClearFinish <= 1'b0;
		end
		// Count all 160 X 120 pixels
		else	
		begin
			if (count_y != 7'd120)
			begin
				if (count_x != 8'd160)
				begin
					xOut <= x + count_x;
					yOut <= y + count_y;
					count_x <= count_x + 1'd1;
					colorOut <= colorIn;
					
				end
				//end up printing current line, move to next line
				else if (count_x == 8'd160)
				begin
					count_x <= 8'd0;
					xOut <= x + count_x;
					yOut <= y + count_y;
					count_y <= count_y + 1'd1;
					colorOut <= colorIn;
				end
			end
			//reaching the button line.
			else
			begin
				xOut <= x + count_x;
				yOut <= y + count_y;
				colorOut <= colorOut;
				signalClearFinish <= 1'b1;
			end
		end
	end

endmodule