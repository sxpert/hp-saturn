/******************************************************************************
 * 3n[xxxxxx]	LC (n) [xxxxxx]
 *
 *
 */ 

// TODO rewrite to avoid having all those display
DECODE_LC_LEN, DECODE_LC:
    begin
        if (runstate == `RUN_DECODE)
            runstate <= `INSTR_START;
        if (runstate == `INSTR_READY)
            case (decstate)
                DECODE_LC_LEN:
                    begin
    `ifdef SIM
                        $write("%5h LC (%h)\t", saved_PC, nibble);
    `endif
                        t_cnt <= nibble;
                        t_ctr <= 0;
                        decstate <= DECODE_LC;
                        runstate <= `INSTR_START;
                    end
                DECODE_LC:
                    begin
                        C[((t_ctr+P)%16)*4+:4] <= nibble;
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
                                t_ctr <= (t_ctr + 1)&4'hf;
                                runstate <= `INSTR_START;
                            end							
                    end
                default:
                    begin
    `ifdef SIM
                        $display("decstate %h nibble %h", decstate, nibble);
    `endif
                        decode_error <= 1;
                    end
            endcase
    end
