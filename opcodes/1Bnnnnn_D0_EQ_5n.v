/******************************************************************************
 *1bnnnnn		DO=(5) nnnnn
 *
 *
 */ 

`include "decstates.v"

`DEC_D0_EQ_5N: begin
    t_cnt <= 4;
    t_ctr <= 1;
    D0[3:0] <= nibble;    
    decstate <= `DEC_D0_EQ_5N_LOOP;
end
`DEC_D0_EQ_5N_LOOP: begin
    D0[t_ctr*4+:4] <= nibble;
    if (t_ctr == t_cnt) begin
        decstate <= `DEC_START;
`ifdef SIM
        $write("%5h D0=(5)\t%1h", inst_start_PC, nibble);
        for(t_ctr = 0; t_ctr != t_cnt; t_ctr ++)
            $write("%1h", D0[(t_cnt - t_ctr - 4'h1)*4+:4]);
        $write("\n");
`endif
    end else 
        t_ctr <= t_ctr + 1;
end