/******************************************************************************
 * 04			SETHEX
 *
 *
 */ 

DECODE_SETHEX:
    if (runstate == `INSTR_READY)
        begin
            hex_dec <= HEX;
            runstate <= `NEXT_INSTR;
`ifdef SIM
            $display("%05h SETHEX", saved_PC);
`endif
        end
// `ifdef SIM
//     else 
//         begin
//             decode_error <= 1;
//             $display("SETHEX runstate %h", runstate);
//         end
// `endif