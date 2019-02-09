/******************************************************************************
 *1bnnnnn		DO=(5) nnnnn
 *
 *
 */ 

`include "decstates.v"

`DEC_D1_EQ_4N,
`DEC_D0_EQ_5N, `DEC_D1_EQ_5N: begin
    case (decstate)
    `DEC_D1_EQ_4N: t_cnt <= 3;
    `DEC_D0_EQ_5N, `DEC_D1_EQ_5N: t_cnt <= 4;
    endcase
    t_ctr <= 1;
    case (decstate)
    `DEC_D0_EQ_5N: begin
        D0[3:0] <= nb_in;    
        decstate <= `DEC_D0_EQ_LOOP;
    end
    `DEC_D1_EQ_4N, `DEC_D1_EQ_5N: begin
        D1[3:0] <= nb_in;    
        decstate <= `DEC_D1_EQ_LOOP;
    end
    endcase
end
`DEC_D0_EQ_LOOP, `DEC_D1_EQ_LOOP: begin
    
    if (decstate == `DEC_D0_EQ_LOOP) 
        D0[t_ctr*4+:4] <= nb_in;
    else 
        D1[t_ctr*4+:4] <= nb_in;
    
    if (t_ctr == t_cnt) begin
        decstate <= `DEC_START;
`ifdef SIM
        $write("%5h D%b=(%1d)\t%1h", inst_start_PC, 
            (decstate == `DEC_D0_EQ_LOOP)?1'b0:1'b1,
            (t_cnt + 1), nb_in);
        for(t_ctr = 0; t_ctr != t_cnt; t_ctr ++)
            $write("%1h", 
                (decstate == `DEC_D0_EQ_LOOP)?
                    D0[(t_cnt - t_ctr - 4'h1)*4+:4]:
                    D1[(t_cnt - t_ctr - 4'h1)*4+:4]
                );
        $write("\n");
`endif
    end else 
        t_ctr <= t_ctr + 1;
end