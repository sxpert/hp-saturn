/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_FX: begin
    case (nb_in)
    4'h8, 4'h9, 4'hA, 4'hB: begin
        if (!hex_dec) begin
            case (nb_in)
            4'h8: {Carry, A[19:0]} <= - A[19:0];
            4'h9: {Carry, B[19:0]} <= - B[19:0];
            4'hA: {Carry, C[19:0]} <= - C[19:0];
            4'hB: {Carry, D[19:0]} <= - D[19:0];
            endcase
            decstate <= `DEC_START;
        end 
`ifdef SIM
        $write("%5h ", inst_start_PC);
        case (nb_in)
        4'h8: $write("A=-A");
        4'h8: $write("B=-B");
        4'h8: $write("C=-C");
        4'h8: $write("D=-D");
        endcase
        if (!hex_dec) $display("\tA");
        else $display("\tA\t\t\t <=== DEC MODE NOT IMPLEMENTED");
`endif
    end
    4'hC, 4'hD, 4'hE, 4'hF: begin
        if (!hex_dec) begin
            case (nb_in)
            4'hC: {Carry, A[19:0]} <= - A[19:0] - 1;
            4'hD: {Carry, B[19:0]} <= - B[19:0] - 1;
            4'hE: {Carry, C[19:0]} <= - C[19:0] - 1;
            4'hF: {Carry, D[19:0]} <= - D[19:0] - 1;
            endcase
            decstate <= `DEC_START;
        end 
`ifdef SIM
        $write("%5h ", inst_start_PC);
        case (nb_in)
        4'h8: $write("A=-A-1");
        4'h8: $write("B=-B-1");
        4'h8: $write("C=-C-1");
        4'h8: $write("D=-D-1");
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
