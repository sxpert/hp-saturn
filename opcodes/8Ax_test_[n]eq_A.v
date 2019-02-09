/******************************************************************************
 * 8Ax
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_8AX: begin
    case (nb_in)
    4'h6: begin
        Carry = !(A[19:0] == C[19:0]);
        $display("%5h ?A#C\tA", inst_start_PC);
    end
    default: begin 
        $display("ERROR : DEC_8AX");
        decode_error <= 1;    
    end
    endcase
    decstate <= `DEC_TEST_GO;
end
