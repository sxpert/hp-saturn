
DECODE_MEMACCESS:
    begin
        if (runstate == `RUN_EXEC)
            begin
                t_ctr <= 0;
                case (t_field)
                    T_FIELD_B:
                        begin
                            t_offset <= 0;
                            t_cnt <= 1;
                        end
                endcase
                case (t_dir)
                    T_DIR_OUT: runstate <= `WRITE_START;
                    T_DIR_IN:  runstate <= `READ_START;
                endcase
    `ifdef SIM
                $write("%5h ", saved_PC);
                case (t_dir)
                    T_DIR_OUT: $write("%s=%s\t", t_ptr?"DAT1":"DAT0", t_reg?"C":"A");
                    T_DIR_IN:  $write("%s=%s\t", t_reg?"C":"A", t_ptr?"DAT1":"DAT0");
                endcase
                case (t_field)
                    T_FIELD_P:   $display("P");
                    T_FIELD_WP:  $display("WP");
                    T_FIELD_XS:  $display("XS");
                    T_FIELD_X:   $display("X");
                    T_FIELD_S:   $display("S");
                    T_FIELD_M:   $display("M");
                    T_FIELD_B:   $display("B");
                    T_FIELD_W:   $display("W");
                    T_FIELD_LEN: $display("%d", t_cnt);
                    T_FIELD_A:   $display("A");
                endcase
    `endif
            end

    // should be in the runstate case 

        if (runstate == `WRITE_START)
            begin
    `ifdef SIM
                $display("`WRITE_START    | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
                            t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_field, t_offset, t_ctr, t_cnt);
    `endif
                bus_command <= `BUSCMD_LOAD_DP;
                bus_address <= (~t_ptr)?D0:D1;
                runstate <= `WRITE_STROBE;
            end
        if (runstate == `WRITE_STROBE)
            begin
    `ifdef SIM
                $display("`WRITE_STROBE | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
                            t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_offset, t_ctr, t_cnt);
    `endif
                bus_command <= `BUSCMD_DP_WRITE;
                bus_nibble_in <= (~t_reg)?A[t_offset*4+:4]:C[t_offset*4+:4];
                t_offset <= t_offset + 1;
                t_ctr <= t_ctr + 1;
                if (t_ctr == t_cnt)
                    begin
                        runstate <= `WRITE_DONE;
                    end
            end
        if (runstate == `WRITE_DONE)
            begin
    `ifdef SIM
                $display("`WRITE_DONE   | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
                            t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_offset, t_ctr, t_cnt);
    `endif
                bus_command <= `BUSCMD_NOP;
                runstate <= `NEXT_INSTR;
            end
    end
