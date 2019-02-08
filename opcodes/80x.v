
/******************************************************************************
 * 80
 * a lot of things start with 80...
 *
 */ 

`include "decstates.v"

`DEC_80X: begin
    case (nibble)
    4'h5:
`include "opcodes/805_CONFIG.v"
    4'ha:   
`include "opcodes/80A_RESET.v"
    4'hc:	decstate <= `DEC_C_EQ_P_N;
    default: begin
        $display("ERROR : DEC_80X");
        decode_error <= 1;
    end
    endcase
end
