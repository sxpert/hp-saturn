/******************************************************************************
 * Dx
 * register manipulation field A
 *
 */ 


`include "decstates.v"

`DEC_DX: begin
    case (nb_in)
    4'hA: begin
        A[19:0] <= C[19:0];
        $display("%5h A=C\tA", inst_start_PC);
    end
    4'hE: begin
        A[19:0] <= C[19:0];
        C[19:0] <= A[19:0];
        $display("%5h ACEX\tA", inst_start_PC);
    end
    default: begin 
        $display("ERROR : DEC_DX");
        decode_error <= 1;    
    end
    endcase
    decstate <= `DEC_START;
end
