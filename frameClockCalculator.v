module frameClockCalculator(frameClock, resetLow, frameOut);
	input frameClock;
	input resetLow;
	output frameOut;
	
	reg [40:0] q;
	always @(posedge frameClock, negedge resetLow)
	begin
		if (resetLow == 1'b0)
			q <= 0;
		else
		begin
			if (q == 0)
					q <= 833333 * 3; //frame count, 50_000_000/60
			else
				q <= q - 1'b1; //reduce
		end
	end

	assign frameOut = (q == 0) ? 1 : 0;

endmodule