/******************************************************************************
 * B[ab]x
 * 
 * lots of things there
 *
 */ 


`include "decstates.v"
`include "fields.v"

`DEC_Bxx_EXEC: begin
    if (!field_table[0]) begin
        if (!nb_in[3]) begin
            alu_reg_dest <= {2'b0, nb_in[1:0]};
            alu_reg_src1 <= {2'b0, nb_in[1:0]};
            if (!nb_in[2]) begin
            end else alu_op <= `ALU_OP_INC;
        end else begin 
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
end