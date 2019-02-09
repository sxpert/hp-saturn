/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

`include "decstates.v"

`DEC_BX: begin
    case (nb_in)
    4'h8, 4'h9, 4'hA, 4'hB, 4'hC, 4'hD, 4'hE, 4'hF: begin
        
    end
    default: begin
        $display("ERROR : DEC_BX");
        decode_error <= 1;
    end
    endcase
end
