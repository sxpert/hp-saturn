
/******************************************************************************
 * A[ab]x
 * 
 * lots of things there
 *
 */ 


`include "decstates.v"
`include "fields.v"

`DEC_AX: begin
    if (!nibble[3]) begin   // table a
        case (nibble)
        4'h0: t_field <= `T_FIELD_P;
        4'h1: t_field <= `T_FIELD_WP;
        4'h2: t_field <= `T_FIELD_XS;
        4'h3: t_field <= `T_FIELD_X;
        4'h4: t_field <= `T_FIELD_S;
        4'h5: t_field <= `T_FIELD_M;
        4'h6: t_field <= `T_FIELD_B;
        4'h7: t_field <= `T_FIELD_W;
        endcase
        decstate <= `DEC_AaX_EXEC;
    end else begin          // table b
        case (nibble)
        4'h8: t_field <= `T_FIELD_P;
        4'h9: t_field <= `T_FIELD_WP;
        4'hA: t_field <= `T_FIELD_XS;
        4'hB: t_field <= `T_FIELD_X;
        4'hC: t_field <= `T_FIELD_S;
        4'hD: t_field <= `T_FIELD_M;
        4'hE: t_field <= `T_FIELD_B;
        4'hF: t_field <= `T_FIELD_W;
        endcase
        decstate <= `DEC_AbX_EXEC;
    end
end
`DEC_AaX_EXEC: begin
    case (nibble)
    default: begin
        $display("ERROR : DEC_AaX_EXEC");
        decode_error <= 1;
    end
    endcase
end
`DEC_AbX_EXEC: begin
    case (nibble)
    4'h2: begin             // C=0  b
        case (t_field)
        `T_FIELD_B: C[7:0] <= 0;
        default: begin
            $display("ERROR :");
            decode_error <= 1;
        end
        endcase
`ifdef SIM
        $write("%5h C=0\t", inst_start_PC);
        case (t_field)
        `T_FIELD_P:  $display("P");
        `T_FIELD_WP: $display("WP");
        `T_FIELD_XS: $display("XS");
        `T_FIELD_X:  $display("X");
        `T_FIELD_S:  $display("S");
        `T_FIELD_M:  $display("M");
        `T_FIELD_B:  $display("B");
        `T_FIELD_W:  $display("W");
        endcase
`endif
    end
    default: begin
        $display("ERROR : DEC_AbX_EXEC");
        decode_error <= 1;
    end
    endcase
    decstate <= `DEC_START;
end