/******************************************************************************
 * 80Cn		C=P	n
 *
 *
 */

DECODE_C_EQ_P_N:
    begin
        if (runstate == `RUN_DECODE)
            runstate <= `INSTR_START;
        if (runstate == `INSTR_READY)
            begin
                C[nibble*4+:4] <= P;
                runstate <= `NEXT_INSTR;
    `ifdef SIM
                $display("%05h C=P\t%h", saved_PC, nibble);	
    `endif
            end
    end
