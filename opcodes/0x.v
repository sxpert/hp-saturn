/******************************************************************************
 * 0X			
 *
 *
 */ 

DECODE_0:
	begin
		if (runstate == `RUN_DECODE)
			runstate <= `INSTR_START;
		if  (runstate == `INSTR_READY)
			case (nibble)
				4'h3: decstate <= DECODE_RTNCC;
				4'h4: decstate <= DECODE_SETHEX;
				4'h5: decstate <= DECODE_SETDEC;
				default: 
					begin
						decode_error <= 1;
	`ifdef SIM
						$display("%05h 0%h => unimplemented", saved_PC, nibble);
	`endif
					end
			endcase
	end
