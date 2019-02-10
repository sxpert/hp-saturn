/******************************************************************************
 * 1[45]
 *
 *	---------- field -----------
 *	 A	 B	 fs	 d
 *	----------------------------	
 *	140	148	150a	158x	DAT0=A field	0000 1000
 *	141	149	151a	159x	DAT1=A field	0001 1001
 *	142	14A	152a	15Ax	A=DAT0 field	0010 1010
 *	143	14B	153a	15Bx	A=DAT1 field	0011 1011
 *	144	14C	154a	15Cx	DAT0=C field	0100 1100
 *	145	14D	155a	15Dx	DAT1=C field	0101 1101
 *	146	14E	156a	15Ex	C=DAT0 field	0110 1110
 *	147	14F	157a	15Fx	C=DAT1 field	0111 1111
 *
 *	fs: P  WP XS X  S  M  B  W
 *	a:  0  1  2  3  4  5  6  7
 *
 *	x = d - 1		x = n - 1
 *	
 */ 

 `include "decstates.v"
 `include "bus_commands.v"
 `include "fields.v"

`DEC_14X, `DEC_15X: begin
    t_ptr <= nb_in[0];
    add_out <= nb_in[0] ? D1 : D0;
    t_dir <= nb_in[1];
    t_reg <= nb_in[2];
    if (decstate == `DEC_14X) begin
        if (!nb_in[3]) begin
            t_field <= `T_FIELD_A;  
            t_cnt <= 4;
            t_ctr <= 0;
        end else begin 
            t_field <= `T_FIELD_B;
            t_cnt <= 1;
            t_ctr <= 0;
        end
        t_ftype <= `T_FTYPE_FIELD;
        next_cycle <= `BUSCMD_LOAD_DP;
        decstate <= `DEC_MEMAXX;
    end else begin
        t_ftype <= nb_in[3];
        decstate <= `DEC_15X_FIELD;
    end
end

`DEC_15X_FIELD: begin
    if (!t_ftype) // fields
        case (nb_in)
        4'h0: begin
            t_field <= `T_FIELD_P;
            t_cnt <= P;
            t_ctr <= P;
        end
        4'h7: begin
            t_field <= `T_FIELD_W;
            t_cnt <= 15;
            t_ctr <= 0;
        end
        default: begin
            $display("ERROR : DEC_15X_FIELD %h", nb_in);
            decode_error <= 1;    
        end
        endcase
    else begin
        t_cnt = nb_in;
        t_ctr = 0;
    end
    next_cycle <= `BUSCMD_LOAD_DP;
    decstate <= `DEC_MEMAXX;
end
 
`DEC_MEMAXX, `DEC_MEMAXX_END: begin
    next_cycle <= t_dir ? `BUSCMD_DP_READ : `BUSCMD_DP_WRITE;  
    case (next_cycle)
    `BUSCMD_LOAD_DP: $write("BUSCMD_LOAD_DP");
    `BUSCMD_DP_WRITE: $write("BUSCMD_WRITE_DP");
    `BUSCMD_DP_READ: $write("BUSCMD_READ_DP");
    default: $write("UNKNOWN %h", next_cycle);
    endcase
    $display(" | CNT %h | CTR %h", t_cnt, t_ctr);
    if (t_dir == `T_DIR_IN) begin
        if (next_cycle != `BUSCMD_LOAD_DP) begin
            case (t_reg) 
            `T_REG_A: begin
                A[t_ctr*4+:4] <= nb_in;
                $display("DP_READ (%h) A[%h] = %h", t_cnt, t_ctr, nb_in);
            end
            `T_REG_C: begin
                C[t_ctr*4+:4] <= nb_in;
                $display("DP_READ (%h) C[%h] = %h", t_cnt, t_ctr, nb_in);
            end
            endcase
            if (t_cnt != t_ctr)
                t_ctr <= (t_ctr + 1) & 15;
        end
    end else begin
        if (decstate == `DEC_MEMAXX) begin
            case (t_reg)
            `T_REG_A: begin
                nb_out <= A[t_ctr*4+:4];
                $display("DP_WRITE (%h) A[%h] = %h", t_cnt, t_ctr, A[t_ctr*4+:4]);
            end
            `T_REG_C: begin
                nb_out <= C[t_ctr*4+:4];
                $display("DP_WRITE (%h) C[%h] = %h", t_cnt, t_ctr, C[t_ctr*4+:4]);
            end
            endcase
        end
        // needs an extra cycle
        if (t_cnt == t_ctr) begin
            $display("go to DEC_MEMAXX_END");
            decstate <= `DEC_MEMAXX_END;
        end else t_ctr <= (t_ctr + 1) & 15;
    end


    if ((t_cnt==t_ctr) &
        (((t_dir == `T_DIR_IN) & (decstate == `DEC_MEMAXX)&(next_cycle!=`BUSCMD_LOAD_DP)) |
         ((t_dir == `T_DIR_OUT) & (decstate == `DEC_MEMAXX_END)))) begin
        $display("---------------------------- DEC_MEMAXX_END -------------------------------");
        decstate <= `DEC_START;
        next_cycle <= `BUSCMD_PC_READ;

        // display the instruction code

        $write("%5h ", inst_start_PC);
        if (t_dir == `T_DIR_IN) begin
            $write("%s=DAT%b\t", t_reg?"C":"A", t_ptr);
        end else begin
            $write("DAT%b=%s\t", t_ptr, t_reg?"C":"A");
        end
        if (!t_ftype)
            case (t_field)
            `T_FIELD_P:	  $display("P");    
            `T_FIELD_WP:  $display("WP");
            `T_FIELD_XS:  $display("XS");
            `T_FIELD_X:	  $display("X");
            `T_FIELD_S:	  $display("S");
            `T_FIELD_M:	  $display("M");
            `T_FIELD_B:	  $display("B");
            `T_FIELD_W:	  $display("W");
            `T_FIELD_A:   $display("A");
            endcase
        else $display("%2d", t_cnt+1);
    end
end
