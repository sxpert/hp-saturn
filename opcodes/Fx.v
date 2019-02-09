/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_FX: begin
    case (nibble)
    4'h8, 4'h9, 4'hA, 4'hB: begin
        if (!hex_dec) begin
            case (nibble)
            4'h8: {Carry, A[19:0]} <= - A[19:0];
            4'h9: {Carry, B[19:0]} <= - B[19:0];
            4'hA: {Carry, C[19:0]} <= - C[19:0];
            4'hB: {Carry, D[19:0]} <= - D[19:0];
            endcase
            decstate <= `DEC_START;
        end 
`ifdef SIM
        $write("%5h ", inst_start_PC);
        case (nibble)
        4'h8: $write("A=-A");
        4'h8: $write("B=-B");
        4'h8: $write("C=-C");
        4'h8: $write("D=-D");
        endcase
        if (!hex_dec) $display("\tA");
        else $display("\tA\t\t\t <=== DEC MODE NOT IMPLEMENTED");
`endif
    end
    default: begin 
        $display("ERROR : DEC_FX");
        decode_error <= 1;    
    end
    endcase
end
