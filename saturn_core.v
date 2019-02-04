/**************************************************************************************************
 *
 *
 *
 *
 *
 */

module hp_rom (
	input 		clk,
	input 		[19:0]	address,
	input		enable,
	output	reg	[3:0]	nibble_out	
);
localparam 	ROM_FILENAME = "rom-gx-r.hex";

reg [3:0]	rom	[0:(2**20)-1];

//reg[3:0]	rom	[0:(2**16)-1];

initial
begin
	if ( ROM_FILENAME != "" )
		$readmemh( ROM_FILENAME, rom);
end

always @(posedge clk)
	if (enable)
		nibble_out <= rom[address];
endmodule

/**************************************************************************************************
 *
 *
 *
 *
 *
 */

module saturn_core (
`ifdef SIM
	input			clk,
	input			reset,
	output			halt,
	output [3:0] 	runstate,
	output [31:0] 	decstate
`else
	input			clk_25mhz
`endif
);

localparam RUN_START	= 0;
localparam READ_ROM_STA	= 1;
localparam READ_ROM_CLK	= 2;
localparam READ_ROM_STR	= 3;
localparam READ_ROM_VAL	= 4;
localparam RUN_EXEC		= 14;
localparam RUN_DECODE	= 15;

// decoder stuff

localparam DECODE_START		= 32'h00000000;

localparam DECODE_0			= 32'h00000001;
localparam DECODE_0X		= 32'h00000002;

localparam DECODE_1			= 32'h00000010;
localparam DECODE_1X		= 32'h00000011;
localparam DECODE_14		= 32'h00000410;
localparam DECODE_15		= 32'h00000510;
localparam DECODE_MEMACCESS	= 32'h00000411;
localparam DECODE_D0_EQ_5N	= 32'h00000b10;

localparam DECODE_P_EQ		= 32'h00000020;

localparam DECODE_LC_LEN	= 32'h00000030;
localparam DECODE_LC		= 32'h00000031;

localparam DECODE_GOTO		= 32'h00000060;

localparam DECODE_8			= 32'h00000080;
localparam DECODE_8X		= 32'h00000081;
localparam DECODE_80		= 32'h00000082;

localparam DECODE_RESET		= 32'h0000A080;

localparam DECODE_C_EQ_P_N	= 32'h0000C080;

localparam DECODE_82		= 32'h00000280;

localparam DECODE_ST_EQ_0_N	= 32'h00000480;
localparam DECODE_ST_EQ_1_N	= 32'h00000580;

localparam DECODE_GOVLNG	= 32'h00000d80;
localparam DECODE_GOSBVL	= 32'h00000f80;

localparam DECODE_A			= 32'h000000a0;
localparam DECODE_A_FS		= 32'h000000a1;

localparam HEX			= 0;
localparam DEC			= 1;

// state machine stuff
reg			halt;
reg	[3:0]	runstate;
reg	[31:0]	decstate;

// memory access
reg			rom_clock;
reg	[19:0]	rom_address;
reg			rom_enable;
wire[3:0]	rom_nibble;

// internal registers
reg	[3:0]	nibble;
reg	[19:0]  saved_PC;
reg	[2:0]	rstk_ptr;
reg	[19:0]  jump_base;
reg	[19:0]	jump_offset;
reg			hex_dec;
reg	[3:0]	load_cnt;
reg	[3:0]	load_ctr;
reg [3:0]	tmp_field;

// processor registers
reg	[19:0]	PC;
reg	[3:0]	P;
reg	[15:0]  ST;
reg	[3:0]	HST;
reg			Carry;
reg	[19:0]	RSTK[0:7];
reg	[19:0]	D0;
reg	[19:0]	D1;

reg	[63:0]	A;
reg	[63:0]	B;
reg	[63:0]	C;
reg	[63:0]	D;

reg	[63:0]	R0;
reg	[63:0]	R1;
reg	[63:0]	R2;
reg	[63:0]	R3;
reg	[63:0]	R4;

hp_rom calc_rom (
	.clk		(clk),
	.address	(rom_address),
	.enable		(rom_enable),
	.nibble_out	(rom_nibble)
);

/**************************************************************************************************
 *
 * one single process...
 *
 */

always @(posedge clk)
begin

	if (reset)
		begin
			hex_dec		<= HEX;
			rstk_ptr	<= 7;

			PC			<= 0;
			P			<= 0;
			ST			<= 0;
			HST			<= 0;
			Carry		<= 0;
			RSTK[0]		<= 0;
			RSTK[1]		<= 0;
			RSTK[2]		<= 0;
			RSTK[3]		<= 0;
			RSTK[4]		<= 0;
			RSTK[5]		<= 0;
			RSTK[6]		<= 0;
			RSTK[7]		<= 0;

			D0			<= 0;
			D1			<= 0;

			A			<= 0;
			B			<= 0;
			C			<= 0;
			D			<= 0;

			R0			<= 0;
			R1			<= 0;
			R2			<= 0;
			R3			<= 0;
			R4			<= 0;

			halt		<= 0;
			runstate	<= RUN_START;
			decstate 	<= DECODE_START;
		end
	else
		if (runstate == RUN_START) 
			runstate <= READ_ROM_STA;

//--------------------------------------------------------------------------------------------------
//
// REGISTER UTILITIES
//
//--------------------------------------------------------------------------------------------------

// display registers
`ifdef SIM
	if ((runstate == RUN_START) & (~reset))
		begin
			saved_PC <= PC;
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

//--------------------------------------------------------------------------------------------------
//
// ROM HANDLING
//
//--------------------------------------------------------------------------------------------------

// read from rom start
	if (runstate == READ_ROM_STA)
		begin
			//$display("READ_ROM_STA");
			rom_enable <= 1'b1;
			rom_address <= PC;
			runstate <= READ_ROM_CLK;
		end

// read from rom clock in
	if (runstate == READ_ROM_CLK)
		begin				
			//$display("READ_ROM_CLK");
			rom_clock <= 1'b1;
			runstate <= READ_ROM_STR;
		end

// read from rom store
	if (runstate == READ_ROM_STR)
		begin				
			//$display("READ_ROM_STR");
			nibble <= rom_nibble;
			//$display("PC: %h | read => %h", PC, rom_nibble);
			PC <= PC + 1;
			rom_enable <= 1'b0;
			rom_clock <= 1'b0;
			runstate <= READ_ROM_VAL;
		end


//--------------------------------------------------------------------------------------------------
//
// INSTRUCTION DECODING
//
//--------------------------------------------------------------------------------------------------

// first nibble instruction decoder
	if ((runstate == READ_ROM_VAL) & (decstate == DECODE_START))
		begin
			//$display("READ_ROM_VAL -> instruction decoder");
			runstate <= RUN_DECODE;
			case (nibble)
				//4'h0 : decstate <= DECODE_0;
				//4'h1 : decstate <= DECODE_1;
				4'h2 : decstate <= DECODE_P_EQ;
				//4'h3 : decstate <= DECODE_LC;

				4'h6 : decstate <= DECODE_GOTO;
				4'h8 : decstate <= DECODE_8;
				//4'ha : decstate <= DECODE_A_FS;
				default: 
					begin
`ifdef SIM
						$display("%05h nibble %h => unimplemented", saved_PC, nibble);
`endif
						halt <= 1;
					end
			endcase
		end
/*
task decode_0;
	case (decstate )
		DECODE_START:
			begin
				decstate  <= DECODE_0X;
				read_state <= READ_START;
			end
		DECODE_0X:
			if (read_state != READ_VALID) read_rom();
			else decode_0x();
	endcase		
endtask

task decode_0x;
	case (nibble)
		4'h3: inst_rtncc();
		4'h4: inst_sethex();
		default: instruction_decoder_unhandled();
	endcase
endtask

// 03		RTNCC
task inst_rtncc;
	begin
		Carry = 0;
		PC = RSTK[rstk_ptr];
		RSTK[rstk_ptr] = 0;		
		rstk_ptr = rstk_ptr - 1;
		$display("%05h RTNCC", saved_PC);
		end_decode();
	end
endtask

// 04		SETHEX
task inst_sethex;
	begin
		hex_dec = HEX;
		$display("%05h SETHEX", saved_PC);
		end_decode();
	end
endtask

task decode_1;
	case (decstate )
		DECODE_START:
			begin
				decstate  = DECODE_1X;
				read_state = READ_START;
			end
		DECODE_1X:
			if (read_state != READ_VALID) read_rom();
			else decode_1x();
	endcase		
endtask

task decode_1x;
	case (nibble)
		4'h4, 4'h5:	decode_14_15();
		4'hb:	 	inst_d0_eq_5n();
		default: 	instruction_decoder_unhandled();
	endcase
endtask

task decode_14_15;
	case (decstate)
		DECODE_1X: 
			begin
				read_state <= READ_START;
				case (nibble)
					4'h4: decstate <= DECODE_14;
					4'h5: decstate <= DECODE_15;
				endcase
			end
		DECODE_14, DECODE_15:
			if (read_state != READ_VALID) read_rom();
			else
				case (nibble)
					default:
						begin
							$display("memacess %h %h", decstate[11:8], nibble);
							halt_processor();
						end
				endcase
	endcase 
endtask

// 1bnnnnn	DO=(5) nnnnn
task inst_d0_eq_5n;
	case (decstate )
		DECODE_1X:
			begin
				decstate  = DECODE_D0_EQ_5N;
				read_state = READ_START;
				load_cnt = 4;
				load_ctr = 0;
				$write("%5h D0=(5)\t", saved_PC);
			end
		DECODE_D0_EQ_5N:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					D0[load_ctr*4+:4] = nibble;
					$write("%1h", nibble);
					if (load_ctr == load_cnt) 
						begin
							$display("");
							end_decode();
						end 
					else 
						begin 
							load_ctr = load_ctr + 1;
							read_state = READ_START;
						end
				end
	endcase
endtask

*/

/******************************************************************************
 * 2n			P= 		n
 *
 *
 */ 
 
	if (decstate == DECODE_P_EQ)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					P <= nibble;
`ifdef SIM
					$display("%05h P=\t%h", saved_PC, nibble);	
`endif
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default:
				begin
`ifdef SIM
					$display("runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/*

// 3nxxxxxxxxxxxxxxxx	LC xxxxxxxxxxxxxxxx
task inst_lc;
	case (decstate )
		DECODE_START:
			begin
				decstate  = DECODE_LC_LEN;
				read_state = READ_START;
			end
		DECODE_LC_LEN:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					load_cnt = nibble;
					load_ctr = 0;
					decstate  = DECODE_LC;
					read_state = READ_START;
					$write("%5h LC (%h)\t", saved_PC, load_cnt);
				end
		DECODE_LC:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					C[((load_ctr+P)%16)*4+:4] = nibble;
					$write("%1h", nibble);
					if (load_ctr == load_cnt) 
						begin
							$display("");
							end_decode();
						end 
					else 
						begin 
							load_ctr = (load_ctr + 1)%4'hf;
							read_state = READ_START;
						end
				end
	endcase
endtask
*/

/******************************************************************************
 * 6zyx			GOTO	xyz
 * 
 *
 */ 

	if (decstate == DECODE_GOTO)
		case (runstate)
			RUN_DECODE:
				begin
					runstate <= READ_ROM_STA;
					jump_base <= PC;
					jump_offset <= 0;
					load_cnt <= 2;
					load_ctr <= 0;
`ifdef SIM
					$write("%5h GOTO\t", saved_PC);
`endif
				end
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					jump_offset[load_ctr*4+:4] <= nibble;
`ifdef SIM
					$write("%1h", nibble);
`endif
					if (load_ctr == load_cnt) runstate <= RUN_EXEC;
					else 
						begin 
							load_ctr <= load_ctr + 1;
							runstate <= READ_ROM_STA;
						end
				end
			RUN_EXEC:
				begin
`ifdef SIM
					$display("\t=> %05h", jump_base + jump_offset);
`endif					PC <= jump_base + jump_offset;
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end 
			default: 
				begin
`ifdef SIM
					$display("runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 * 8
 * a lot of things start with 8...
 *
 */ 

	if (decstate == DECODE_8)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					case (nibble)
						4'h0: decstate <= DECODE_80;
						//4'h2: decode_82();
						4'h4: decstate <= DECODE_ST_EQ_0_N;
						4'h5: decstate <= DECODE_ST_EQ_1_N;
						4'hd: decstate <= DECODE_GOVLNG;
						//4'hf: decstate <= DECODE_GOSBVL;
						default:
							begin
`ifdef SIM
								$display("unhandled instruction prefix 8%h", nibble);
`endif
								halt <= 1;
							end
					endcase
					runstate <= RUN_DECODE;
				end
			default: 
				begin
`ifdef SIM
					$display("runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 * 80
 * a lot of things start with 80...
 *
 */ 

	if (decstate == DECODE_80)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					case (nibble)
						//4'h5:	inst_config();
						4'ha:   decstate <= DECODE_RESET;
						4'hc:	decstate <= DECODE_C_EQ_P_N;
						default:
							begin
`ifdef SIM
								$display("unhandled instruction prefix 80%h", nibble);
`endif
								halt <= 1;
							end
					endcase
					runstate <= RUN_DECODE;
				end
			default: 
				begin
`ifdef SIM
					$display("DECODE_80 runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase
		
/*

// 805		CONFIG
task inst_config;
	begin
		$display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
		end_decode();
	end
endtask
*/

/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

	if ((decstate == DECODE_RESET) & (runstate == RUN_DECODE))	
		begin
			$display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
			runstate <= RUN_START;
			decstate <= DECODE_START;
		end

/******************************************************************************
 * 80Cn		C=P	n
 *
 *
 */ 

	if (decstate == DECODE_C_EQ_P_N)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					C[nibble*4+:4] <= P;
`ifdef SIM
					$display("%05h C=P\t%h", saved_PC, nibble);	
`endif
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default: 
				begin
`ifdef SIM
					$display("DECODE_80C runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/*

task decode_82;
	case (decstate )
		DECODE_8X:
			begin
				decstate  <= DECODE_82;
				read_state <= READ_START;
			end
		DECODE_82:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					HST <= HST & ~nibble;
					case (nibble)
						4'h1:	 $display("%5h XM=0", saved_PC);
						4'h2:	 $display("%5h SB=0", saved_PC);
						4'h4:    $display("%5h SR=0", saved_PC);
						4'h8:	 $display("%5h MP=0", saved_PC);
						4'hf:    $display("%5h CLRHST", saved_PC);
						default: $display("%5h CLRHST	%f", saved_PC, nibble);
					endcase
					end_decode();
				end
	endcase
endtask
*/

/******************************************************************************
 * 84n	ST=0   n
 * 85n	ST=1   n
 */ 

	if ((decstate == DECODE_ST_EQ_0_N) | (decstate == DECODE_ST_EQ_1_N))
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
					case (decstate)
						DECODE_ST_EQ_0_N: 
							begin
`ifdef SIM
								$display("%05h ST=0\t%h", saved_PC, nibble);
`endif
								ST[nibble] <= 0;
							end
						DECODE_ST_EQ_1_N:
							begin
`ifdef SIM
								$display("%05h ST=1\t%h", saved_PC, nibble);
`endif
								ST[nibble] <= 1;
							end
					endcase
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default:
				begin
`ifdef SIM
					$display("decstate %h", decstate);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 * 8Dzyxwv	GOVLNG		vwxyz
 * 8Fzyxwv	GOSBVL		vwxyz
 * two for the price of one...
 */ 

	if ((decstate == DECODE_GOVLNG) | (decstate == DECODE_GOSBVL))
		case (runstate)
			RUN_DECODE:
				begin
					jump_base <= 0;
					load_cnt <= 4;
					load_ctr <= 0;
`ifdef SIM
					case (decstate)
						DECODE_GOVLNG: $write("%5h GOVLNG\t", saved_PC);
						DECODE_GOSBVL: $write("%5h GOSBVL\t", saved_PC);
					endcase
`endif
					if (decstate == DECODE_GOSBVL)
						rstk_ptr <= rstk_ptr + 1;
					runstate <= READ_ROM_STA;
				end
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: ;
			READ_ROM_VAL:
				begin
				  //$display("decstate %h | nibble %h", decstate, nibble);
				  jump_base[load_ctr*4+:4] = nibble;
`ifdef SIM
				  $write("%1h", nibble);
`endif
				  if (load_ctr == load_cnt) runstate <= RUN_EXEC;
					else 
						begin 
							load_ctr <= load_ctr + 1;
							runstate <= READ_ROM_STA;
						end
				end
			RUN_EXEC:
				begin
`ifdef SIM
					$display("\t=> %5h", jump_base);
`endif
					if (decstate  == DECODE_GOSBVL)
						RSTK[rstk_ptr] <= PC;							  
					PC <= jump_base;
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default:
				begin
`ifdef SIM
					$display("decstate %h", decstate);
`endif
					halt <= 1;
				end
		endcase

/*
task decode_a;
	case (decstate)
		DECODE_START:
			begin
				decstate  <= DECODE_A;
				read_state <= READ_START;
			end
		DECODE_A:
			if (read_state != READ_VALID) read_rom();
			else 
				begin
					tmp_field <= nibble;
					decstate <= DECODE_A_FS;
					read_state <= READ_START;
				end
	endcase		
endtask
	
task decode_a_fs;
	case (decstate)
		DECODE_A_FS:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					$write("%5h ", saved_PC);
					case (tmp_field)
						4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7:
							begin
								$display("a%h%h", tmp_field, nibble);
								halt_processor();
							end
						4'h8, 4'h9, 4'ha, 4'hb, 4'hc, 4'hd, 4'he, 4'hf:
							begin
								case (nibble)
									4'h2: // C=0 fs
										begin
											$write("C=0\t");
											case (tmp_field)
												4'he: C[7:0] <= 0;
												default: 
													begin
														$display("a%h%h", tmp_field, nibble);
														halt_processor();
													end
											endcase
										end
									default: 
										begin
											$display("a%h%h", tmp_field, nibble);
											halt_processor();
										end
								endcase
								case (tmp_field)
									4'he: $display("B");
								endcase
								if (~halt)
									end_decode();
							end
					endcase
				end
	endcase
endtask
*/
end
endmodule

`ifdef SIM

module saturn_tb;
reg			clk;
reg			reset;
wire		halt;
wire [3:0]	runstate;
wire [31:0]	decstate;

saturn_core saturn (
	.clk		(clk),
	.reset		(reset),
	.halt		(halt),
	.runstate	(runstate),
	.decstate	(decstate)
);

always 
    #10 clk = (clk === 1'b0);

initial begin
	//$monitor ("c %b | r %b | run %h | dec %h", clk, reset, runstate, decstate);
end 

initial begin
	$display("starting the simulation");
	clk <= 0;
	reset <= 1;
	@(posedge clk);
	reset <= 0;
	@(posedge halt);
	$finish;
end		


endmodule

`else


`endif