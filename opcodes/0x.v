/******************************************************************************
 * 0X			
 *
 *
 */ 

`DEC_0X: begin
	case (nibble)
	// RTNSXM
	4'h0: begin
		HST[0] <= 1;
		new_PC <= RSTK[rstk_ptr];
		RSTK[rstk_ptr] <= 0;		
		rstk_ptr <= rstk_ptr - 1;
		next_cycle <= `BUSCMD_LOAD_PC;
		decstate <= `DEC_START;
	`ifdef SIM
		$display("%05h RTNSXM", inst_start_PC);
	`endif
	end
	4'h3:
`include "opcodes/03_RTNCC.v"
	4'h4:
`include "opcodes/04_SETHEX.v"
	4'h5:
`include "opcodes/05_SETDEC.v"
	default: begin
        $display("ERROR : DEC_0X");
        decode_error <= 1;
    end
    endcase
end

