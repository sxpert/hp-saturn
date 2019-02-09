/******************************************************************************
 * 0X			
 *
 *
 */ 

`DEC_0X: begin
	
	//generic RTN suff
	case (nb_in)
	4'h0, 4'h1, 4'h2, 4'h3: begin
		new_PC <= RSTK[rstk_ptr];
		RSTK[rstk_ptr] <= 0;		
		rstk_ptr <= rstk_ptr - 1;
		next_cycle <= `BUSCMD_LOAD_PC;
		decstate <= `DEC_START;
	end
	default: begin end
	endcase

	// things specific to the
	case (nb_in)
	4'h0: begin
		HST[0] <= 1;
		`ifdef SIM
		$display("%05h RTNSXM", inst_start_PC);
		`endif
	end
	4'h1: begin
		`ifdef SIM
		$display("%05h RTN", inst_start_PC);
		`endif
	end
	4'h2: begin
		Carry <= 1;
		`ifdef SIM
		$display("%05h RTNSC", inst_start_PC);
		`endif
	end
	4'h3: begin
		Carry <= 0;
		`ifdef SIM
		$display("%05h RTNCC", inst_start_PC);
		`endif
	end
	4'h4: begin
		hex_dec <= `MODE_HEX;
		decstate <= `DEC_START;
		`ifdef SIM
		$display("%05h SETHEX", inst_start_PC);
		`endif
	end
	4'h5: begin
		hex_dec <= `MODE_DEC;
		decstate <= `DEC_START;
		`ifdef SIM
		$display("%05h SETDEC", inst_start_PC);
		`endif
	end
	default: begin
        $display("ERROR : DEC_0X");
        decode_error <= 1;
    end
    endcase
end

