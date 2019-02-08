/******************************************************************************
 * 6xxx			GOSUB 		xxx
 *
 *
 */ 

`include "decstates.v"
`include "bus_commands.v"

`DEC_GOSUB: begin
    //$display("DEC_GOTO : nibble %h", nibble);
    jump_offset <= 0;
    t_cnt <= 2;
    t_ctr <= 1;
    jump_offset[3:0] <= nibble;
    rstk_ptr <= rstk_ptr + 1;
    decstate <= `DEC_GOSUB_LOOP;
end
`DEC_GOSUB_LOOP: begin
    $display("PC %h | t_cnt %d | t_ctr %d | jump_offset %h", PC, t_cnt, t_ctr, jump_offset);
    jump_offset[t_ctr*4+:4] <= nibble;
    if (t_ctr == t_cnt) begin
        new_PC <= PC + 1 + {8'h00, nibble, jump_offset[7:0]};
        next_cycle <= `BUSCMD_LOAD_PC;
        decstate <= `DEC_START;
        RSTK[rstk_ptr] <= PC + 1;
`ifdef SIM
        $display("%5h GOSUB\t%3h\t=> %05h", 
            inst_start_PC, 
            {nibble, jump_offset[7:0]}, 
            PC + 1 + {8'h00, nibble, jump_offset[7:0]});
`endif
    end else t_ctr <= t_ctr + 1;
end
