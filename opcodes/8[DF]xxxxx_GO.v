/******************************************************************************
 * 8Dzyxwv	GOVLNG		vwxyz
 * 8Fzyxwv	GOSBVL		vwxyz
 * two for the price of one...
 */ 

`include "decstates.v"

`DEC_GOVLNG, `DEC_GOSBVL: begin
    jump_base <= 0;
    t_cnt <= 4;
    t_ctr <= 1;
    jump_base[3:0] <= nibble;
    if (decstate == `DEC_GOSBVL) begin
        rstk_ptr <= rstk_ptr + 1;
        decstate <= `DEC_GOSBVL_LOOP;
    end else decstate <= `DEC_GOVLNG_LOOP;
end
`DEC_GOVLNG_LOOP, `DEC_GOSBVL_LOOP: begin
    jump_base[t_ctr*4+:4] <= nibble;
    if (t_ctr == t_cnt) begin
        if (decstate == `DEC_GOVLNG_LOOP) decstate <= `DEC_GOVLNG_EXEC;
        else decstate <= `DEC_GOSBVL_EXEC;
        execute_cycle <= 1;
    end else t_ctr <= t_ctr + 1;
end
`DEC_GOVLNG_EXEC, `DEC_GOSBVL_EXEC: begin
    $display("GOSBVL new_PC %5h", new_PC);
    $display("GOSBVL PC     %5h", PC);
    if (decstate  == `DEC_GOSBVL_EXEC) RSTK[rstk_ptr] <= new_PC;							  
    new_PC <= jump_base;
    bus_load_pc <= 1;
    execute_cycle <= 0;
    decstate <= `DEC_START;
`ifdef SIM
    $write("%5h GO", saved_PC);
    case (decstate)
        `DEC_GOVLNG_EXEC: $write("VLNG");
        `DEC_GOSBVL_EXEC: $write("SBVL");
    endcase
    $display("\t%5h", jump_base);
`endif
end
