/******************************************************************************
 * 6xxx			GOTO 		xxx
 *
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

`DEC_GOTO: begin
    //$display("DEC_GOTO : nibble %h", nibble);
    jump_base <= PC;
    jump_offset <= 0;
    t_cnt <= 2;
    t_ctr <= 1;
    jump_offset[3:0] <= nb_in;
    decstate <= `DEC_GOTO_LOOP;
end
`DEC_GOTO_LOOP: begin
    //$display("jump_base %h | t_cnt %d | t_ctr %d | jump_offset %h", jump_base, t_cnt, t_ctr, jump_offset);
    jump_offset[t_ctr*4+:4] <= nb_in;
    if (t_ctr == t_cnt) begin
        new_PC <= jump_base + {8'h00, nb_in, jump_offset[7:0]};
        next_cycle <= `BUSCMD_LOAD_PC;
        decstate <= `DEC_START;
`ifdef SIM
        $display("%5h GOTO\t%3h\t=> %05h", 
            inst_start_PC, 
            {nb_in, jump_offset[7:0]}, 
            jump_base + {8'h00, nb_in, jump_offset[7:0]});
`endif
    end else t_ctr <= t_ctr + 1;
end
