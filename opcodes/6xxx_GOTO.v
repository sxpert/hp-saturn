/******************************************************************************
 * 6xxx			GOTO 		xxx
 *
 *
 */ 

`include "decstates.v"

`DEC_GOTO: begin
    //$display("DEC_GOTO : nibble %h", nibble);
    jump_base <= PC;
    jump_offset <= 0;
    t_cnt <= 2;
    t_ctr <= 1;
    jump_offset[3:0] <= nibble;
    decstate <= `DEC_GOTO_LOOP;
end
`DEC_GOTO_LOOP: begin
    //$display("jump_base %h | t_cnt %d | t_ctr %d | jump_offset %h", jump_base, t_cnt, t_ctr, jump_offset);
    jump_offset[t_ctr*4+:4] <= nibble;
    if (t_ctr == t_cnt) begin
        execute_cycle <= 1;
        decstate <= `DEC_GOTO_EXEC;
    end else t_ctr <= t_ctr + 1;
end
`DEC_GOTO_EXEC: begin
    //$display("DEC_GOTO_EXEC");
    new_PC <= jump_base + jump_offset;
    bus_load_pc <= 1;
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $display("%5h GOTO\t%3h\t=> %05h", inst_start_PC, jump_offset[11:0], jump_base + jump_offset);
`endif
end
