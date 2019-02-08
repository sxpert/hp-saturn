/******************************************************************************
 * 0X			
 *
 *
 */ 

`DEC_0X: begin
	case (nibble)
	4'h3:
`include "opcodes/03_RTNCC.v"
		// execute_cycle <= 1;
		// decstate <= `DEC_RTNCC;
	4'h4: begin 
`include "opcodes/04_SETHEX.v"
		// execute_cycle <= 1;
		// decstate <= `DEC_SETHEX;
	end
	4'h5: begin
		execute_cycle <= 1;
		decstate <= `DEC_SETDEC;
	end
	default: begin
        $display("ERROR : DEC_0X");
        decode_error <= 1;
    end
    endcase
end

