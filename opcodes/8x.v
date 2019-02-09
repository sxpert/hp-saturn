/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_8X: begin
    case (nb_in)
    4'h0: decstate <= `DEC_80X;
    4'h2: decstate <= `DEC_82X_CLRHST;
    4'h4: decstate <= `DEC_ST_EQ_0_N;
    4'h5: decstate <= `DEC_ST_EQ_1_N;
    4'hA: decstate <= `DEC_8AX;
    4'hD: decstate <= `DEC_GOVLNG;
    4'hF: decstate <= `DEC_GOSBVL;
    default: begin 
        $display("ERROR : DEC_8X");
        decode_error <= 1;    
    end
    endcase
end
