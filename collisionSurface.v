module collisionSurface(evaluateCollision, yBird, resetLow, clk, crashHappen);
	input evaluateCollision;
	input [6:0] yBird;

	input resetLow;
	input clk;
	output reg crashHappen;
	
	always@(posedge clk)
	if (!resetLow)
		crashHappen <= 1'b0;
	else
	begin
		if (evaluateCollision)
		begin
			if (crashHappen == 0)
			begin
				if (yBird >= 7'd116)
					crashHappen <= 1'b1;
				else
					crashHappen <= 1'b0;
			end
			else
				crashHappen <= 1'b1;
		end
	end
	
endmodule