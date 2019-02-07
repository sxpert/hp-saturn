/******************************************************************************
 *1bnnnnn		DO=(5) nnnnn
 *
 *
 */ 

DECODE_D0_EQ_5N:
    begin
        if (runstate == `RUN_DECODE)
            begin
                runstate <= `INSTR_START;
                t_cnt <= 4;
                t_ctr <= 0;
    `ifdef SIM
                $write("%5h D0=(5)\t", saved_PC);
    `endif
            end
        if (runstate == `INSTR_READY)
            begin
                D0[t_ctr*4+:4] <= nibble;
    `ifdef SIM
                $write("%1h", nibble);
    `endif
                if (t_ctr == t_cnt)
                    begin
    `ifdef SIM
                        $display("");
    `endif
                        runstate <= `NEXT_INSTR;
                    end
                else 
                    begin 
                        t_ctr <= t_ctr + 1;
                        runstate <= `INSTR_START;
                    end
            end
    end
