/******************************************************************************
 * 84n	ST=0   n
 * 85n	ST=1   n
 */ 

DECODE_ST_EQ_0_N, DECODE_ST_EQ_1_N:
    begin
        if (runstate == `RUN_DECODE)
            runstate <= `INSTR_START;
        if (runstate == `INSTR_READY)
            begin
                case (decstate)
                    DECODE_ST_EQ_0_N: 
                        begin
                            ST[nibble] <= 0;
    `ifdef SIM
                            $display("%05h ST=0\t%h", saved_PC, nibble);
    `endif
                        end
                    DECODE_ST_EQ_1_N:
                        begin
                            ST[nibble] <= 1;
    `ifdef SIM
                            $display("%05h ST=1\t%h", saved_PC, nibble);
    `endif
                        end
                endcase
                runstate <= `NEXT_INSTR;
            end
    end
