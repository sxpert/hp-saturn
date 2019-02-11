/******************************************************************************
 * Cx
 * maths...
 *
 */ 


`include "decstates.v"

`DEC_CX: begin
    case (nb_in)
    4'hA: begin
        if (!hex_dec) begin
            {Carry, A[19:0]} = A[19:0] + C[19:0];
            decstate <= `DEC_START;
        end 


`ifdef SIM
        $display("%5h A=A+C\tA%s", inst_start_PC, hex_dec?"\t\t\t <=== DEC MODE NOT IMPLEMENTED":"");
`endif
    end
    default: begin 
        $display("ERROR : DEC_CX");
        decode_error <= 1;    
    end
    endcase
end
