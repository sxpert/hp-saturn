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
 
DECODE_14, DECODE_15:
    begin
        if (runstate == `RUN_DECODE)
            runstate <= `INSTR_START;
        if (runstate == `INSTR_READY)
            begin
                if (decstate == DECODE_14)
                    begin
                        t_ptr <= nibble[0];
                        t_dir <= nibble[1];
                        t_reg <= nibble[2];
                        if (~nibble[3]) t_field <= T_FIELD_A;
                        else t_field <= T_FIELD_B;
                        decstate <= DECODE_MEMACCESS;
                        runstate <= `RUN_EXEC;
    `ifdef SIM
                        $display("14%h ", nibble);
    `endif
                    end
                else
                    begin
                        decode_error <= 1;
    `ifdef SIM
                        $display("15%h UNIMPLEMENTED", nibble);
    `endif
                    end
            end
    end
`include "opcodes/1[45]_memaccess_exec.v"
