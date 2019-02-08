/******************************************************************************
 * 3n[xxxxxx]	LC (n) [xxxxxx]
 *
 *
 */ 

`include "decstates.v"

`DEC_LC_LEN: begin
    t_cnt <= nibble;
    t_ctr <= 0;
    decstate <= `DEC_LC;
end
`DEC_LC: begin
    C[((t_ctr+P)%16)*4+:4] <= nibble;
    if (t_ctr == t_cnt) begin
        decstate <= `DEC_START;
`ifdef SIM
        $write("%5h LC (%h)\t%1h", saved_PC, t_cnt, nibble);
        for(t_ctr = 0; t_ctr != t_cnt; t_ctr ++)
            $write("%1h", C[(((t_cnt - t_ctr - 4'h1)+P)%16)*4+:4]);
        $write("\n");
`endif
    end else begin 
        t_ctr <= (t_ctr + 1)&4'hf;
    end							
end
