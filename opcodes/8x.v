/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 


`include "decstates.v"

`DEC_8X: begin
    case (nibble)
    4'h0: decstate <= `DEC_80X;
    4'h4: decstate <= `DEC_ST_EQ_0_N;
    4'h5: decstate <= `DEC_ST_EQ_1_N;
    4'hD: decstate <= `DEC_GOVLNG;
    4'hF: decstate <= `DEC_GOSBVL;
    default: begin 
        $display("ERROR : DEC_8X");
        decode_error <= 1;    
    end
    endcase
end

// DECODE_8:
//     case (runstate)
//         `RUN_DECODE: runstate <= `INSTR_START;
//         `INSTR_START, `INSTR_STROBE: begin end
//         `INSTR_READY:
//             begin
//                 case (nibble)
//                     4'h0: decstate <= DECODE_80;
//                     4'h2: decstate <= DECODE_82;
//                     4'h4: decstate <= DECODE_ST_EQ_0_N;
//                     4'h5: decstate <= DECODE_ST_EQ_1_N;
//                     4'hd: decstate <= DECODE_GOVLNG;
//                     4'hf: decstate <= DECODE_GOSBVL;
//                     default:
//                         begin
//     `ifdef SIM
//                             $display("unhandled instruction prefix 8%h", nibble);
//     `endif
//                             decode_error <= 1;
//                         end
//                 endcase
//                 runstate <= `RUN_DECODE;
//             end
//         default: 
//             begin
//     `ifdef SIM
//                 $display("DECODE_8: runstate %h", runstate);
//     `endif
//                 decode_error <= 1;
//             end
//     endcase