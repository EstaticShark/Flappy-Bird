module downForce(dropActionSignal, flapActive, oldOrCurrent, yOut, clk, resetLow);

	input dropActionSignal; // from datapath, is dropEnable on or off
	input flapActive;
	input clk;
	input resetLow;
	input oldOrCurrent;
	output wire [6:0] yOut;
	
	reg signed [7:0] currentY;
	reg signed [7:0] oldY;

	reg signed [6:0] directionSpeed; //velocity
	wire [3:0] gravity;
	assign gravity = 4'd1;
	wire [6:0] initialDirectiondirectionSpeed;
	
	assign yOut = oldOrCurrent ? currentY : oldY; //old pos or current pos
	assign initialDirectiondirectionSpeed = 7'd2;
	
	always @(posedge clk)
	begin
		if (!resetLow)
		begin
			currentY <= 8'd58;
			oldY <= 8'd58;
			directionSpeed <= initialDirectiondirectionSpeed;
		end
		if (flapActive) // jump on
		begin
			// jump up.
			directionSpeed <= initialDirectiondirectionSpeed;
			if (dropActionSignal)
			begin
				oldY <= currentY;
				/*
					JUST IN CASE THE CODE DOESNT RUN, REVERT BACK TO THE INITIAL STATE WHERE THE ONLY
					LINES BELOW THIS WAS:
				
					currentY <= currentY - initialDirectiondirectionSpeed;
				*/
				if (currentY - directionSpeed >= 0)
				begin
					currentY <= currentY - initialDirectiondirectionSpeed;
				end
			end
		end	
		else if (dropActionSignal) // no flap, just free fall now
			begin
				if (currentY - directionSpeed >= 0 && currentY - directionSpeed <= 116) // within boundary, you can freefall normally
				begin
					oldY <= currentY;
					currentY <= currentY - directionSpeed;
					directionSpeed <= directionSpeed - gravity;
				end
				else if (currentY - directionSpeed < 0) //boundary handling
				begin
					if (currentY == 8'd0)
						oldY <= 8'd0;
					else
						oldY <= currentY;
					currentY <= 8'd0;
					directionSpeed <= directionSpeed - gravity;
				end
				else if (currentY - directionSpeed > 116) // boundary handling
				begin
					if (currentY == 8'd116)
						oldY <= 8'd116;
					else
						oldY <= currentY;
					currentY <= 116;
				end
			end
	end

endmodule
