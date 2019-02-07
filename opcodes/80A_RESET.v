/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

DECODE_RESET:
    if (runstate == `RUN_DECODE)
        begin
            runstate <= `NEXT_INSTR;
    `ifdef SIM
            $display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
    `endif
        end
    // `ifdef SIM
    // else 
    //     begin
    //         decode_error <= 1;
    //         $display("RESET runstate %h", runstate);
    //     end
    // `endif
