/*
	GAME INSTRUCTIONS
	
	When you first open the VGA module, the game will not work just yet, the
	first step to playing the game is to hit the reset button, which is KEY[0]
	at the moment. By hitting the reset button you will be brought to the game,
	you can start the game by hitting the fly button, which is KEY[1]. You will
	fly up by pressing KEY[1] and can gain points for passing through each pipe.
	Your score is shown on the De1-Soc board in hexadecimal notation :)
	
	If you happen to be playing on the version with KEY[1] as fly and are having
	trouble getting the bird to fly without lag, then try pressing the top of KEY[1]
	which happens to give input to the bird more consistently. You may also want
	to try using different boards, as we have found varying amounts of success
	playing the game on different boards.
*/

module flappyBird
	(
		CLOCK_50, /*On Board 50 MHz*/
		
		/*Your inputs and outputs here*/
      KEY,
      SW,
		
		/*KEYBOARD*/
		PS2_CLK,
	   PS2_DAT,
		  
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,						//	VGA Blue[9:0]
		HEX0,
		HEX1,
		LEDR
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	inout PS2_CLK;
	inout PS2_DAT;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output [9:0] LEDR;
	output [6:0] HEX1;
	output [6:0] HEX0;
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
		.resetn(resetn),
		.clock(CLOCK_50),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(writeEn),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK)
		);
		
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
		
		
	/*									PS2 Keyboard Input
		
		This is the wiring for the PS2 keyboard module which is instantiated
		below, at the moment it takes all sorts of inputs but the only code
		related wiring it has at the moment is the space bar to this flap
		wire. At the moment this will remain here, if we can get this working
		in the lab with the PS2 keyboard then this will be part of the final
		product, but at the time of 12/4/2019 we do not have the functionality
		of the keyboard module attached to the actual project
	*/
	wire keyboard_flap;
	wire flap;
	assign flap = ~keyboard_flap;

	
	
	//others
	wire [7:0] points; //wire to track score
	wire fm; //when frame count done this goes high
	wire old_cur; //is old visual position or new visual position in consideration, if old we must erase it and replace with new visual and new pos (for animation)
	wire load_en; //load signal for datapath
	wire [6:0] y_out;
	wire printEnd; //signal for whether printing in datapath is done
	wire moveEn_ac; //drop bird signal
	wire jumpEn; // flap enabled signal
	wire jump_state_achieved; //in correct flap state
	wire is_crash; // did we crash :(
	
	//blackscreen (reset) vs regular gameplay
	wire [2:0] colour_clear;
	wire [7:0] x_clear;
	wire [6:0] y_clear;
	wire [2:0] colour_go;
	wire [7:0] x_go;
	wire [6:0] y_go;
	wire clr_go; // clrCanvasXYOrRetainXYToVGA
	wire clr_load_en; //signal to blackScreen calculator generated from controller, whether to do clear calculation
	wire clr_end_signal; //is clear calculation done?
	
	assign jumpEn = jump_state_achieved & !is_crash; // flap is a go
	//assign LEDR[9:0] = {is_crash,is_crash,is_crash,is_crash,is_crash,is_crash,is_crash,is_crash,is_crash,is_crash}; //light up all ledr when crash


	
   //main datapath
	datapath data1(
		/*Inputs*/
		.xInput(8'd78),
		.yInput(y_out),
		.loadDatapath(load_en),
		.clk(CLOCK_50),
		.resetLow(KEY[0]),
		.oldOrCurrent(old_cur),
		
		/*Outputs*/
		.xOut(x_go), 
		.yOut(y_go), 
		.colorOut(colour_go),
		.finishedPrintingSignal(printEnd), 
		.collisionHappened(is_crash),
		.points(points)
		);

   //fsm control
	controller control1(
		/*Inputs*/
		.flap(KEY[1]/*flap*/), 
		.frameactive(fm),
		.clk(CLOCK_50),
		.resetLow(KEY[0]),
		.outputFinish(printEnd),
		.collisionOccurred(is_crash),
		.clrCanvasFinish(clr_end_signal),
		
		/*Outputs*/
		.plotEnable(writeEn),
		.oldOrCurrent(old_cur),
		.loadEnableDataPath(load_en), 
		.dropEnable(moveEn_ac),
		.clrCanvasScreenEnable(clr_load_en),
		.clrCanvasXYOrRetainXYToVGA(clr_go)
		);
	
	//controller for jump states
	flapController control2(
		/*Inputs*/
		.flap(KEY[1]/*flap*/), 
		.clk(CLOCK_50), 
		.resetLow(KEY[0]),
		
		/*Outputs*/
		.flapStateEnabled(jump_state_achieved)
		);
	
	// gravity module for bird
	downForce gravity(
		/*Inputs*/
		.dropActionSignal(moveEn_ac),
		.flapActive(jumpEn), 
		.oldOrCurrent(old_cur),
		.clk(CLOCK_50), 
		.resetLow(KEY[0]),
		
		/*Outputs*/
		.yOut(y_out)
		);
	
	// counter for frame
	frameClockCalculator frames1(
		/*Inputs*/
		.frameClock(CLOCK_50), 
		.resetLow(KEY[0]), 
		
		/*Outputs*/
		.frameOut(fm)
		);
	
	// module acting as a pathway to select clear XY (for black screen) or regular XY (in-game) to send to VGA 
	vgaFacilitatorForBlackOrNormalState vgabOrN(
		/*Inputs*/
		.sendClearOrRegular(clr_go), 
		.xClear(x_clear),
		.yClear(y_clear),
		.colorClear(colour_clear),
		.xRegular(x_go), 
		.yRegular(y_go),
		.colorRegular(colour_go),
		
		/*Outputs*/
		.xOut(x),
		.yOut(y),
		.colorOut(colour)
		);
	
	//module to output x clear and y clear wires containing data for clear xy coordinates
	blackScreenCalculator blkScreen(
		/*Inputs*/
		.colorIn(3'b000),
		.enableLoad(clr_load_en),
		.clk(CLOCK_50), 
		.resetLow(resetn), 
		
		/*Outputs*/
		.xOut(x_clear),
		.yOut(y_clear), 
		.colorOut(colour_clear),
		.signalClearFinish(clr_end_signal)
		);

	//show points
	decoder dec0(
		/*Inputs*/
		.in(points[3:0]),
		
		/*Outputs*/
		.hex(HEX0)
		);
		
	decoder dec1(
		/*Inputs*/
		.in(points[7:4]),
		.hex(HEX1)
		);
	
	
	// PS2 Keyboard
	keyboard_tracker #(.PULSE_OR_HOLD(1)) player_input(
		/*Inputs*/
		.clock(CLOCK_50),
		.reset(KEY[0]),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		
		/*Outputs*/
		.w(LEDR[4]),
		.a(LEDR[5]),
		.s(LEDR[6]),
		.d(LEDR[7]),
		.left(LEDR[0]),
		.right(LEDR[1]),
		.up(LEDR[2]),
		.down(LEDR[3]),
		.space(keyboard_flap),
		.enter(LEDR[9])
		);
	
    
endmodule

module decoder(in, hex);
	input [3:0] in;
   output [6:0] hex;
	
	assign hex[0] = ~((in[3] | in[2] | in[1] | ~in[0]) & (in[3] | ~in[2] | in[1] | in[0])
		& (~in[3] | ~in[2] | in[1] | ~in[0]) & (~in[3] | in[2] | ~in[1] | ~in[0]));

	assign hex[1] = ~((in[3] | ~in[2] | in[1] | ~in[0]) & (~in[3] | ~in[2] | in[1] | in[0]) 
		& (~in[3] | ~in[1] | ~in[0]) & (~in[2] | ~in[1] | in[0]));

	assign hex[2] = ~((~in[3] | ~in[2] | in[1] | in[0]) & (in[3] | in[2] | ~in[1] | in[0]) 
		& (~in[3] | ~in[2] | ~in[1]));

	assign hex[3] = ~((in[3] | ~in[2] | in[1] | in[0]) & (in[3] | in[2] | in[1] | ~in[0]) 
		& (~in[2] | ~in[1] | ~in[0]) & (~in[3] | in[2] | ~in[1] | in[0]));

	assign hex[4] = ~((in[3] | ~in[2] | in[1]) & (in[2] | in[1] | ~in[0]) & (in[3] | ~in[0]));

	assign hex[5] = ~((~in[3] | ~in[2] | in[1] | ~in[0]) & (in[3] | in[2] | ~in[0]) 
		& (in[3] | in[2] | ~in[1]) & (in[3] | ~in[1] | ~in[0]));

	assign hex[6] = ~((in[3] | in[2] | in[1]) & (in[3] | ~in[2] | ~in[1] | ~in[0]) 
		& (~in[3] | ~in[2] | in[1] | in[0]));

endmodule
