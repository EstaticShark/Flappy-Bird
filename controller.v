module controller(flap, clk, frameactive, resetLow, outputFinish, collisionOccurred, clrCanvasFinish, plotEnable, 
			oldOrCurrent, loadEnableDataPath, dropEnable, clrCanvasScreenEnable, clrCanvasXYOrRetainXYToVGA);
			
	input flap;
	input frameactive;
	input clk;
	input resetLow;
	input outputFinish;
	input collisionOccurred;
	input clrCanvasFinish;
	output reg plotEnable;
	output reg oldOrCurrent;
	output reg loadEnableDataPath;
	output reg dropEnable;
	output reg clrCanvasScreenEnable;
	output reg clrCanvasXYOrRetainXYToVGA;
	
   localparam  waitOnFrameDone = 4'd0, // wait on frame count completion (see frameCounter)
               eraseSetUp = 4'd1,
					erase = 4'd2,
					nextVisualSetUp = 4'd3,
					nextVisual = 4'd4,
					continuation = 4'd5,
					checkForCollision = 4'd6,
					collisionState = 4'd7,
					clrCanvas = 4'd8, // BLACK SCREEN, (count and then plot pixels)
					clrCanvasSetUp = 4'd9, // load stage for clrCanvas (clr values for XY etc)
					initialFrameSetUp = 4'd10, // load stage for initial frame
					initialFrame = 4'd11,
					waitForFlap = 4'd12; // wait on first flap (key[0] press) to start game
   
	reg [3:0] next_state;
	reg [3:0] current_state;
	
   // Next state logic aka our state table
   always@(*)
   begin: state_table 
           case (current_state) 
					clrCanvasSetUp: 		next_state = clrCanvas; //press KEY[0] (reset) once game initialized to properly clrCanvas, load stage for clrCanvas
					clrCanvas:				next_state = clrCanvasFinish ? initialFrameSetUp : clrCanvas; // wait on clrCanvasFinish signal true, all clrCanvas computation done and plotted
					initialFrameSetUp: 	next_state = initialFrame; // settting up pipe, first coin, bird starting pixel
					initialFrame: 			next_state = outputFinish ? waitForFlap : initialFrame; //loop till first screen finished generation
					waitForFlap: 			next_state = flap ? waitForFlap : waitOnFrameDone; //loop till key[0] (flap) pressed to start game
					waitOnFrameDone: 		next_state = frameactive ? eraseSetUp : waitOnFrameDone; //loop til frame complete (frame count to zero)
					eraseSetUp: 			next_state = erase; //load stage for erase, erase is for cleaning last position of visuals in preparation for next pos of visuals (animation!)
					erase: 					next_state = outputFinish ? nextVisualSetUp: erase; //loop here till its done plotting
					nextVisualSetUp: 		next_state = nextVisual; //load stage for next frame, prev position erased, so now load up values for next continuationment (frame)
               nextVisual: 			next_state = outputFinish ? checkForCollision : nextVisual; //loop stage till frame complete (frame count to zero)
					checkForCollision: 	next_state = collisionOccurred ? collisionState : continuation; //check if collision has occured
					continuation: 			next_state = waitOnFrameDone; // if no collision, continue continuationment
					collisionState: 		next_state = waitOnFrameDone; // if collision. In datapath if crash occured then x coordinate stops and gravity is solely applied, causing straight vertical down fall.
					default:     next_state = waitOnFrameDone;
       endcase
   end // state_table
   
	// current_state registers
   always@(posedge clk)
   begin: state_FFs
		if(!resetLow)
			begin
				current_state <= clrCanvasSetUp;
			end
      else
           current_state <= next_state;
   end // state_FFS
	
	always @(*)
	begin: enable_signals
		dropEnable = 1'b0;
		clrCanvasScreenEnable = 1'b0;
		clrCanvasXYOrRetainXYToVGA = 1'b1;
		plotEnable = 1'b0;
		loadEnableDataPath = 1'b0;
		oldOrCurrent = 1'b0;
		case (current_state)
			waitOnFrameDone:	plotEnable = 1'b0;
			eraseSetUp: begin // we need to erase previosuly made items in preparation for next visuals (erase prev frame for next frame, animation!)
				loadEnableDataPath = 1'b1;// enable load to datapath BUT set oldOrCurrent to 0 so dataPath knows old pos of visuals are being recontinuationd.
				oldOrCurrent = 1'b0;
			end
			erase: begin // erase is plotted, all prev positions are plotted in white and will then be overwritten with new positions (in next state)
				loadEnableDataPath = 1'b0;
				plotEnable = 1'b1;
			end
			nextVisualSetUp: begin // set up values for next continuationment of visuals (prev pos been erased in prev state)
				loadEnableDataPath = 1'b1;
				oldOrCurrent = 1'b1;
			end
			nextVisual: begin // draw the newly positioned visuals
				loadEnableDataPath = 1'b0;
				plotEnable = 1'b1;
			end
			continuation: begin
				dropEnable = 1'b1; //gravity enabled
			end
			collisionState: begin
				dropEnable = 1'b1; //gravity enabled (vertically down, as in datapath x is halted from change)
			end
			clrCanvasSetUp: begin
				clrCanvasScreenEnable = 1'b1; //Start clrCanvas computation for x and y coordinates (black screen) (see datapath_clrCanvas)
				clrCanvasXYOrRetainXYToVGA = 1'b0; //Pass in clrCanvased XY to vga (low for clrCanvased XY)
			end
			clrCanvas: begin //BLACK SCREEN
				clrCanvasScreenEnable = 1'b0; //Start count for pixels plot
				clrCanvasXYOrRetainXYToVGA = 1'b0;
				plotEnable = 1'b1; // Plot enabled to vga
			end
			initialFrameSetUp: begin
				loadEnableDataPath = 1'b1; // Start pipe, coin(first coin), and player creation for initial frame generation (starting screen)
				oldOrCurrent = 1'b1; //No pipes made previosuly so they are current, (no moving animation at this point)
			end
			initialFrame: begin
				loadEnableDataPath = 1'b0; // start count for pixels plot(bird, pipes, coin), pass to vga
				plotEnable = 1'b1; // plot enabled to vga, plot the pixels
			end
		endcase
	end
	
endmodule