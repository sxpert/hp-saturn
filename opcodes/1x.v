/******************************************************************************
 * 1X
 *
 *
 */ 

DECODE_1:
    begin
        if (runstate == `RUN_DECODE)
            runstate <= `INSTR_START;
        if (runstate == `INSTR_READY)
            begin
                case (nibble)
                    //4'h4, 4'h5:	decode_14_15();
                    4'h4:	decstate <= DECODE_14;
                    4'hb:	decstate <= DECODE_D0_EQ_5N;
                    default:
                        begin
                            decode_error <= 1;
    `ifdef SIM
                            $display("unhandled instruction prefix 1%h", nibble);
    `endif
                        end
                endcase
                runstate <= `RUN_DECODE;
            end
    end