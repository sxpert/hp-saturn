

/****
 * Instruction data read
 *
 *
 */

`define NEXT_INSTR    0
`define NEXT_NIBBLE	  1
`define INSTR_START   2
`define INSTR_STROBE  3
`define INSTR_READY	  4

`define READ_START    5
`define READ_STROBE   6
`define READ_DONE     7
`define READ_VALUE    8

`define WRITE_START   9
`define WRITE_STROBE 10
`define WRITE_DONE   11

`define RUN_DECODE   12
`define RUN_EXEC     13

`define RUN_INIT     15

	case (runstate)
		`RUN_INIT:
			begin
`ifdef SIM
				$display("RUN_INIT => NEXT_INSTR");
`endif
				first_nibble <= 0;
				first_nibble_ready <= 0;
				nibble_ready <= 0;
				bus_load_pc <= 1;
				runstate <=  `NEXT_INSTR;
			end
		`NEXT_INSTR:
			begin
				if (bus_load_pc)
					begin
						bus_address <= PC;
						bus_command <= `BUSCMD_LOAD_PC;
						bus_load_pc <= 0;
						runstate <= `INSTR_START;
					end
				else
					begin
						bus_command <= `BUSCMD_PC_READ;
						runstate <= `INSTR_STROBE;
					end
				first_nibble <= 1;
				first_nibble_ready <= 0;
				nibble_ready <= 0;
				saved_PC <= PC;
				decstate <= DECODE_START;
`ifdef SIM
				// display registers
				$display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", PC, Carry, hex_dec?"DEC":"HEX", rstk_ptr, RSTK[7]);
				$display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", P, HST, ST, RSTK[6]);
				$display("A:  %h    R0:  %h   RSTK5: %5h", A, R0, RSTK[5]);
				$display("B:  %h    R1:  %h   RSTK4: %5h", B, R1, RSTK[4]);
				$display("C:  %h    R2:  %h   RSTK3: %5h", C, R2, RSTK[3]);
				$display("D:  %h    R3:  %h   RSTK2: %5h", D, R3, RSTK[2]);
				$display("D0: %h  D1: %h    R4:  %h   RSTK1: %5h", D0, D1, R4, RSTK[1]);
				$display("                                                RSTK0: %5h", RSTK[0]);
`endif
			end
		`NEXT_NIBBLE:		// 1
			begin
				first_nibble <= 0;
				first_nibble_ready <= 0;
				nibble_ready <= 0;
			end
		`INSTR_START:		// 2
			begin
				bus_command <= `BUSCMD_PC_READ;
				runstate <= `INSTR_STROBE;
			end
		`INSTR_STROBE:		// 3
			begin
				bus_command <= `BUSCMD_NOP;
				nibble <= bus_nibble_out;
				if (first_nibble)
					first_nibble_ready <= 1;
				else	
					nibble_ready <= 0;
				PC <= PC + 1;
				runstate <= `INSTR_READY;
			end
		`INSTR_READY:		// 4
			if (decstate == DECODE_START)
				begin
					//$display("`READ_VALUE -> instruction decoder");
					runstate <= `RUN_DECODE;
					case (nibble)
						4'h0 : decstate <= DECODE_0;
						4'h1 : decstate <= DECODE_1;
						4'h2 : decstate <= DECODE_P_EQ;
						4'h3 : decstate <= DECODE_LC_LEN;

						4'h6 : decstate <= DECODE_GOTO;
						4'h8 : decstate <= DECODE_8;
						4'ha : decstate <= DECODE_A;
						default: 
							begin
		`ifdef SIM
								$display("%05h nibble %h => unimplemented", saved_PC, nibble);
		`endif
								decode_error <= 1;
							end
					endcase
				end
		`READ_STROBE:		// 5
			begin
				runstate <= `READ_DONE;
			end
		`READ_DONE:			// 6
			begin				
				bus_command <= `BUSCMD_NOP;
				nibble <= bus_nibble_out;
				PC <= PC + 1;
				runstate <= `READ_VALUE;
			end
		`RUN_DECODE,		// C
		`RUN_EXEC:			// D
			begin 
			end
		default:
			begin
`ifdef SIM
				$display("Unhandled runstate %h in main case statement", runstate);
`endif
			end
	endcase

//--------------------------------------------------------------------------------------------------
//
// INSTRUCTION DECODING
//
//--------------------------------------------------------------------------------------------------

case (decstate)
`include "opcodes/0x.v"
`include "opcodes/03_RTNCC.v"
`include "opcodes/04_SETHEX.v"
`include "opcodes/05_SETDEC.v"
`include "opcodes/1x.v"
`include "opcodes/1[45]_memaccess_decode.v"
`include "opcodes/1Bnnnnn_D0_EQ_5n.v"
`include "opcodes/2n_P_EQ.v"
`include "opcodes/3n[x...]_LC.v"
`include "opcodes/6xxx_GOTO.v"
`include "opcodes/8x.v"
`include "opcodes/80x.v"
`include "opcodes/805_CONFIG.v"
`include "opcodes/80A_RESET.v"
`include "opcodes/80Cn_C_EQ_P_n.v"
`include "opcodes/82x_CLRHST.v"
`include "opcodes/8[45]n_ST_EQ_[01]_n.v"
`include "opcodes/8[DF]xxxxx_GO.v"
`include "opcodes/A[ab]x.v"
endcase

