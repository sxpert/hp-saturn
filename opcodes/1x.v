/******************************************************************************
 * 1X
 *
 *
 */ 

`include "decstates.v"

`DEC_1X: begin
    case (nibble)
    4'h4: decstate <= `DEC_14X;
    4'h5: decstate <= `DEC_15X;
    4'hB: decstate <= `DEC_D0_EQ_5N;
    4'hE: decstate <= `DEC_D1_EQ_4N;
    4'hF: decstate <= `DEC_D1_EQ_5N;
    default: begin 
        $display("ERROR : DEC_1X");
        decode_error <= 1;    
    end
    endcase
end
