
/******************************************************************************
 * A[ab]x
 * 
 * lots of things there
 *
 */ 


`include "decstates.v"
`include "fields.v"

`DEC_Axx_EXEC: begin
    if (!field_table[0]) begin
        $display("table 'a' not handled yet");
        decode_error <= 1;
    end else begin
        if (!nb_in[3]) begin
            alu_reg_dest <= {2'b0, nb_in[1:0]};
            if (!nb_in[2]) alu_op <= `ALU_OP_ZERO;
            else begin
                alu_op <= `ALU_OP_COPY;
                alu_reg_src1 <= {nb_in[0], (!(nb_in[0] | nb_in[1])) & nb_in[2]};
            end;
        end else begin
            $display("DEC_Axx_EXEC %h", nb_in);
            decode_error <= 1;
        end
    end
    alu_debug <= 1;
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
`ifdef SIM
    $write("%5h ", inst_start_PC);
    if (!nb_in[3]) 
        case (nb_in[1:0])
        2'b00: $write("A=%s",(!nb_in[2])?"0":"B");
        2'b01: $write("B=%s",(!nb_in[2])?"0":"C");
        2'b10: $write("C=%s",(!nb_in[2])?"0":"A");
        2'b11: $write("D=%s",(!nb_in[2])?"0":"C");
        endcase
    else begin
        $write("NOT HANDLED");
    end
    $write("\t");
    case (field)
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