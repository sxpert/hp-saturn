//--------------------------------------------------------------------------------------------------
//
// instruction decoder
//
//--------------------------------------------------------------------------------------------------

`include "decstates.v"

/*
 * order of register in 4 op blocs has several common combinations
 */
wire [3:0]		reg_ABCD;
wire [3:0]		reg_BCAC;
wire [3:0]		reg_ABAC;
wire [3:0]		reg_BCCD;
wire [3:0]		reg_D0D1;

assign reg_ABCD = {2'b00, nb_in[1:0]};
assign reg_BCAC = {2'b00, nb_in[0], !(nb_in[1] || nb_in[0])};
assign reg_ABAC = {2'b00, nb_in[1] && nb_in[0], (!nb_in[1]) && nb_in[0]};
assign reg_BCCD = {2'b00, nb_in[1] || nb_in[0], (!nb_in[1]) ^  nb_in[0]};
assign reg_D0D1 = {3'b010, (nb_in[0] && nb_in[1]) || (nb_in[2] && nb_in[3])};

always @(posedge dec_strobe) begin
	if (alu_requested_halt) decode_error <= 1;
	if ((next_cycle == `BUSCMD_LOAD_PC)|
		(next_cycle == `BUSCMD_CONFIGURE)|
		(next_cycle == `BUSCMD_RESET)|
		((next_cycle == `BUSCMD_NOP)&
		 (decstate == `DEC_START))) begin
		$display("SETTING next_cycle to BUSCMD_PC_READ");
		next_cycle <= `BUSCMD_PC_READ;
	end else begin
`ifdef SIM
		if ((decstate == `DEC_START)|(decstate == `DEC_TEST_GO)) begin
			// display registers
			$display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", PC, Carry, hex_dec?"DEC":"HEX", rstk_ptr, RSTK[7]);
			$display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", P, HST, ST, RSTK[6]);
			$display("A:  %h    R0:  %h   RSTK5: %5h", A, R0, RSTK[5]);
			$display("B:  %h    R1:  %h   RSTK4: %5h", B, R1, RSTK[4]);
			$display("C:  %h    R2:  %h   RSTK3: %5h", C, R2, RSTK[3]);
			$display("D:  %h    R3:  %h   RSTK2: %5h", D, R3, RSTK[2]);
			$display("D0: %h  D1: %h    R4:  %h   RSTK1: %5h", D0, D1, R4, RSTK[1]);
			$display("                                                RSTK0: %5h", RSTK[0]);
		end
`endif


		$display("CYCLE %d | NEXTC %h | INSTR %d | PC %h | DECSTATE %3h | NIBBLE %h", 
				cycle_ctr, next_cycle,
				(decstate == `DEC_START)?instr_ctr+1:instr_ctr, 
				PC, decstate, nb_in);
		case (decstate)
		`DEC_START:	begin
			// disable ALU debugging at the start of a new instruction
			alu_debug <= 0;
			// reset debugger op_code
			dbg_op_code <= 0;
			instr_ctr <= instr_ctr + 1;
			inst_start_PC <= PC;
			case (nb_in)
			4'h0: decstate <= `DEC_0X;
			4'h1: decstate <= `DEC_1X;
			4'h2: decstate <= `DEC_P_EQ_N;
			4'h3: decstate <= `DEC_LC;
			4'h6: decstate <= `DEC_GOTO;
			4'h7: decstate <= `DEC_GOSUB;
			4'h8: decstate <= `DEC_8X;
			4'hA: begin
				fields_return <= `DEC_Axx_EXEC;
				decstate <= `DEC_ab_FIELDS;
			end
			4'hB: begin
				fields_return <= `DEC_Bxx_EXEC;
				decstate <= `DEC_ab_FIELDS;
			end
			4'hC: decstate <= `DEC_CX;
			4'hD: decstate <= `DEC_DX;
			4'hF: decstate <= `DEC_FX;
			default: begin 
				$display("ERROR : DEC_START");
				decode_error <= 1;
			end
			endcase
		end
`include "opcodes/0x.v"
`include "opcodes/1x.v"
`include "opcodes/13x_ptr_and_AC.v"
`include "opcodes/1[45]_memaccess.v"
`include "opcodes/1[678C]n_D[01]_math_n.v"
`include "opcodes/1[9ABDEF]nnnnn_D[01]_EQ_[245]n.v"
`include "opcodes/2n_P_EQ_n.v"
`include "opcodes/3n[x...]_LC.v"
`include "opcodes/6xxx_GOTO.v"
`include "opcodes/7xxx_GOSUB.v"
`include "opcodes/8x.v"
`include "opcodes/80x.v"
`include "opcodes/808x.v"
`include "opcodes/808[4-B]_[AC]BIT_set_test.v"
`include "opcodes/80[CD]n_C_and_P_n.v"
`include "opcodes/82x_CLRHST.v"
`include "opcodes/8[4567]n_work_test_ST.v"
`include "opcodes/8[89]n_test_P.v"
`include "opcodes/8Ax_test_[n]eq_A.v"
`include "opcodes/8[DF]xxxxx_GO.v"
`include "opcodes/A[ab]x.v"
`include "opcodes/B[ab]x.v"
`include "opcodes/Cx.v"
`include "opcodes/Dx_regs_field_A.v"
`include "opcodes/Fx.v"
`include "opcodes/xx_RTNYES_GOYES.v"

`include "opcodes/z_alu_phase_3.v"
`include "opcodes/z_fields.v"
		default: begin
			$display("ERROR : GENERAL");
			decode_error <= 1;
		end
		endcase
	end
end
