
/******************************************************************************
 * 80
 * a lot of things start with 80...
 *
 */ 

`include "decstates.v"

`DEC_80X: begin
    case (nibble)
    4'h5:   begin
        execute_cycle <= 1;
        decstate <= `DEC_CONFIG;
    end
    4'ha:   begin
        execute_cycle <= 1;
        decstate <= `DEC_RESET;
    end
    4'hc:	decstate <= `DEC_C_EQ_P_N;
    default: begin
        $display("ERROR : DEC_80X");
        decode_error <= 1;
    end
    endcase
end
