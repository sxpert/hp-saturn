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
    t_ptr <= nibble[0];
    t_dir <= nibble[1];
    t_reg <= nibble[2];
    if (decstate == `DEC_14X) begin
        if (!nibble[3]) begin
            t_field <= `T_FIELD_A;  
            t_cnt <= 4;
            t_ctr <= 15;
        end else begin 
            t_field <= `T_FIELD_B;
            t_cnt <= 1;
            t_ctr <= 15;
        end
        next_cycle <= `BUSCMD_LOAD_DP;
        decstate <= `DEC_MEMACCESS;
    end else begin
        decstate <= `DEC_15X_FIELD;
    end
end

`DEC_15X_FIELD: begin
    case (nibble)
    4'h0: begin
        t_field <= `T_FIELD_P;
        t_cnt <= P;
        t_ctr <= (P - 1) & 4'hF;
    end
    default: begin
        $display("ERROR : DEC_15X_FIELD");
        decode_error <= 1;    
    end
    endcase
    next_cycle <= `BUSCMD_LOAD_DP;
    decstate <= `DEC_MEMACCESS;
end
 
`DEC_MEMACCESS: begin
    if (t_cnt==t_ctr) begin
        decstate <= `DEC_START;
        next_cycle <= `BUSCMD_PC_READ;
    end else begin
        t_ctr <= (t_ctr + 1) & 15;
        next_cycle <= t_dir ? `BUSCMD_DP_READ : `BUSCMD_DP_WRITE;    
    end
end