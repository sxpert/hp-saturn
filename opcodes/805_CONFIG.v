/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

DECODE_CONFIG:
    if (runstate == `RUN_DECODE)	
        begin
            runstate <= `NEXT_INSTR;
    `ifdef SIM
            $display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
    `endif
        end
    // `ifdef SIM
    // else 
    //     begin
    //         decode_error <= 1;
    //         $display("CONFIG runstate %h", runstate);
    //     end
    // `endif
