module vgaFacilitatorForBlackOrNormalState(sendClearOrRegular, xClear, yClear, colorClear, xRegular, yRegular, colorRegular, xOut, yOut, colorOut);
	input sendClearOrRegular; //to signal whether we are passing clear (black screen) or regular x and ys to VGA
	input [7:0] xClear;
	input [6:0] yClear;
	input [2:0] colorClear;
	input [7:0] xRegular;
	input [6:0] yRegular;
	input [2:0] colorRegular;
	output reg [7:0] xOut;
	output reg [6:0] yOut;
	output reg [2:0] colorOut;
	
	always @(*)
	begin
		case (sendClearOrRegular)
			/*Clear*/
			1'b0:
			begin
				xOut = xClear;
				yOut = yClear;
				colorOut = colorClear;
			end
			
			/*Regular*/
			1'b1:
			begin
				xOut = xRegular;
				yOut = yRegular;
				colorOut = colorRegular;
			end
		endcase
	end
	
endmodule