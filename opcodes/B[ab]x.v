/******************************************************************************
 * B[ab]x
 * 
 * lots of things there
 *
 */ 


`include "decstates.v"
`include "fields.v"

`DEC_Bxx_EXEC: begin
    if (!field_table[0]) begin // table a
        if (!nb_in[3]) begin // 
            alu_reg_dest <= reg_ABCD;
            alu_reg_src1 <= reg_ABCD;
            if (!nb_in[2]) begin
                alu_reg_src2 <= reg_BCAC;
                alu_op <= `ALU_OP_SUB;
            end else alu_op <= `ALU_OP_INC;
        end else begin          // table b
            $display("Bxx table 'a' not handled yet");
            decode_error <= 1;
        end
    end else begin
        alu_reg_dest <= {2'b0, nb_in[1:0]};
        $display("Bxx table 'b' not handled yet");
        decode_error <= 1;
    end
    alu_debug <= 1;
    next_cycle <= `BUSCMD_NOP;
    decstate <= `DEC_ALU_INIT;
    alu_return <= `DEC_START;

`ifdef SIM

`endif
end