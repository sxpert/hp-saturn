/******************************************************************************
 * xx
 * RTNYES or GOYES
 *
 */ 

`include "decstates.v"

`DEC_TEST_GO: begin
    jump_base <= PC;
    jump_offset <= {{16{1'b0}},nb_in};
    decstate <= `DEC_TEST_GO_1;
end

`DEC_TEST_GO_1: begin
    $display("DEC_TEST_GO_1 opcode %h | base %h | offset %h", 
        {nb_in, jump_offset[3:0]}, jump_base, 
        {{12{nb_in[3]}},nb_in,jump_offset[3:0]});
    if (Carry) begin
        case ({nb_in, jump_offset[3:0]})
        8'h00: begin // RTNYES
            new_PC <= RSTK[rstk_ptr];
            RSTK[rstk_ptr] <= 0;		
            rstk_ptr <= rstk_ptr - 1;
            next_cycle <= `BUSCMD_LOAD_PC;
        end
        default: begin // GOYES
            new_PC <= jump_base + {{12{nb_in[3]}},nb_in,jump_offset[3:0]};
            next_cycle <= `BUSCMD_LOAD_PC;
        end
        endcase   
    end
`ifdef SIM
    $write("%5h ", jump_base);
    case ({nb_in, jump_offset[3:0]})
    8'h00: $display("RTNYES");
    default: $display ("GOYES\t%2h\t=> %5h", {nb_in, jump_offset[3:0]},
        jump_base + {{12{nb_in[3]}},nb_in,jump_offset[3:0]});
    endcase 
`endif
    decstate <= `DEC_START;
 end