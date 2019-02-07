/******************************************************************************
 * 05			SETDEC
 *
 *
 */ 

DECODE_SETDEC:
    if (runstate == `INSTR_READY)   
        begin
            hex_dec <= DEC;
            runstate <= `NEXT_INSTR;
        `ifdef SIM
            $display("%05h SETDEC", saved_PC);
        `endif
        end
// `ifdef SIM
//     else 
//         begin
//             decode_error <= 1;
//             $display("SETDEC runstate %h", runstate);
//         end
// `endif
