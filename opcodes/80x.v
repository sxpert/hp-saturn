
/******************************************************************************
 * 80
 * a lot of things start with 80...
 *
 */ 

`include "decstates.v"

`DEC_80X: begin
    case (nibble)
    4'ha:   begin
        //read_next_pc <= 0;
        execute_cycle <= 1;
        decstate <= `DEC_RESET;
    end
    4'hc:	decstate <= `DEC_C_EQ_P_N;
    default: begin
        $display("ERROR : DEC_80X");
        decode_error <= 1;
    end
    endcase
end

// DECODE_80:
//     case (runstate)
//         `RUN_DECODE: runstate <= `INSTR_START;
//         `INSTR_START, `INSTR_STROBE: begin end
//         `INSTR_READY:
//             begin
//                 case (nibble)
//                     4'h5:   decstate <= DECODE_CONFIG;
//                     4'ha:   decstate <= DECODE_RESET;
//                     4'hc:	decstate <= DECODE_C_EQ_P_N;
//                     default:
//                         begin
// `ifdef SIM
//                             $display("unhandled instruction prefix 80%h", nibble);
// `endif
//                             decode_error <= 1;
//                         end
//                 endcase
//                 runstate <= `RUN_DECODE;
//             end
//         default: 
//             begin
// `ifdef SIM
//                 $display("DECODE_80: runstate %h", runstate);
// `endif
//                 decode_error <= 1;
//             end
//     endcase