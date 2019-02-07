
/******************************************************************************
 * A[ab]x
 * 
 * lots of things there
 *
 */ 

DECODE_A, DECODE_A_FS:
    case (runstate)
        `RUN_DECODE: runstate <= `INSTR_START;
        `INSTR_START, `INSTR_STROBE: begin end
        `INSTR_READY:
            case (decstate)
                DECODE_A: 
                    begin
                        t_field <= nibble;
                        decstate <= DECODE_A_FS;
                        runstate <= `INSTR_START;
                    end
                DECODE_A_FS: 
                    begin				
                        case (nibble)
                            4'h2:
                                case (t_field)
                                    4'he: 
                                        begin
                                            C[7:0] <= 0;
`ifdef SIM
                                            $display("%5h C=0\tB", saved_PC);
`endif
                                        end
                                    default:
                                        begin
`ifdef SIM
                                            $display("A[ab]x.1 decstate %d %h %h", decstate, t_field, nibble);
`endif
                                            decode_error <= 1;
                                        end
                                endcase
                            default:
                                begin
`ifdef SIM
                                    $display("A[ab]x.2 decstate %d %h %h", decstate, t_field, nibble);
`endif
                                    decode_error <= 1;
                                end
                        endcase
                        runstate <= `NEXT_INSTR;
//							decstate <= DECODE_START;
                    end
                default:
                    begin
`ifdef SIM
                        $display("A[ab]x.3 decstate %d %h", decstate, nibble);
`endif
                        decode_error <= 1;
                    end
            endcase
        default:
            begin
`ifdef SIM
                $display("A[ab]x.4 decstate %d runstate %d", decstate, runstate);
`endif
                decode_error <= 1;
            end
    endcase