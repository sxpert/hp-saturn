/******************************************************************************
 * 0X			
 *
 *
 */ 

`DEC_0X: begin
	case (nibble)
	4'h3:
`include "opcodes/03_RTNCC.v"
	4'h4:
`include "opcodes/04_SETHEX.v"
	4'h5:
`include "opcodes/05_SETDEC.v"
	default: begin
        $display("ERROR : DEC_0X");
        decode_error <= 1;
    end
    endcase
end

