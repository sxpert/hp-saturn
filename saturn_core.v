

module hp_rom (
	input 		clk,
	input 		[19:0]	address,
	input		enable,
	output	reg	[3:0]	nibble_out	
);
localparam 	ROM_FILENAME = "rom-gx-r.hex";

reg [7:0]	rom	[0:524287];
//reg[7:0]	rom	[0:4096];

initial
begin
	if ( ROM_FILENAME != "" )
		$readmemh( ROM_FILENAME, rom);
end

always @(posedge clk)
	if (enable)
		nibble_out <= address[0] ? rom[address[19:1]][7:4] : rom[address[19:1]][3:0];	

endmodule


module saturn_core (
	input	clk,
	input	reset,
	output	halt
);

localparam READ_START	= 2'b00;
localparam READ_CLOCK	= 2'b01;
localparam READ_STORE	= 2'b10;
localparam READ_VALID	= 2'b11;

localparam RUN_START   = 1'b0;
localparam RUN_DECODE	= 1'b1;

// decoder stuff

localparam DECODE_START		= 32'h00000000;

localparam DECODE_0			= 32'h00000001;
localparam DECODE_0X		= 32'h00000002;

localparam DECODE_1			= 32'h00000010;
localparam DECODE_1X		= 32'h00000011;
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

localparam HEX			= 0;
localparam DEC			= 1;

// state machine stuff
reg		halt;
reg	[1:0]	read_state;
reg		run_state;
reg	[31:0]	decode_state;

// memory access
reg		rom_clock;
reg	[19:0]	rom_address;
reg		rom_enable;
wire	[3:0]	rom_nibble;

// internal registers
reg	[3:0]	data_nibble;
reg	[19:0]  saved_PC;
reg	[2:0]	rstk_ptr;
reg	[19:0]  jump_base;
reg	[19:0]	jump_offset;
reg		hex_dec;
reg	[3:0]	load_cnt;
reg	[3:0]	load_ctr;
reg	[5:0]	load_disp;

// processor registers
reg	[19:0]	PC;
reg	[3:0]	P;
reg	[15:0]  ST;
reg	[3:0]	HST;
reg		Carry;
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

always @(posedge clk)
begin
	if (reset)
	begin
		read_state <= READ_START;
		run_state <= RUN_START;
		decode_state <= DECODE_START;
		initialize_registers();
	end
	else
		run_nibble();
end


//--------------------------------------------------------------------------------------------------
//
// REGISTER UTILITIES
//
//--------------------------------------------------------------------------------------------------

task initialize_registers;
	begin
		hex_dec <= HEX;
		rstk_ptr <= 7;
	
		PC <= 0;
		P <= 0;
		ST <= 0;
		HST <= 0;
		Carry <= 0;
		RSTK[0] <= 0;
		RSTK[1] <= 0;
		RSTK[2] <= 0;
		RSTK[3] <= 0;
		RSTK[4] <= 0;
		RSTK[5] <= 0;
		RSTK[6] <= 0;
		RSTK[7] <= 0;

		D0 = 0;
		D1 = 0;

		A <= 0;
		B <= 0;
		C <= 0;
		D <= 0;

		R0 <= 0;
		R1 <= 0;
		R2 <= 0;
		R3 <= 0;
		R4 <= 0;

		halt <= 0;
	end
endtask

task display_registers;
	begin
		$display("PC: %05h               Carry: %b h: %s rp: %h   RSTK7: %05h", PC, Carry, hex_dec?"DEC":"HEX", rstk_ptr, RSTK[7]);
		$display("P:  %h  HST: %b        ST:  %b   RSTK6: %5h", P, HST, ST, RSTK[6]);
		$display("A:  %h    R0:  %h   RSTK5: %5h", A, R0, RSTK[5]);
		$display("B:  %h    R1:  %h   RSTK4: %5h", B, R1, RSTK[4]);
		$display("C:  %h    R2:  %h   RSTK3: %5h", C, R2, RSTK[3]);
		$display("D:  %h    R3:  %h   RSTK2: %5h", D, R3, RSTK[2]);
		$display("D0: %h  D1: %h    R4:  %h   RSTK1: %5h", D0, D1, R4, RSTK[1]);
		$display("                                                RSTK0: %5h", RSTK[0]);
	end
endtask


//--------------------------------------------------------------------------------------------------
//
// ROM HANDLING
//
//--------------------------------------------------------------------------------------------------


task read_rom_start;
	begin
		//$display("start read");
		rom_enable <= 1'b1;
		rom_address <= PC;
		read_state <= READ_CLOCK;
	end
endtask

task read_rom_clock;
	begin				
		//$display("clocking rom");
		rom_clock <= 1'b1;
		read_state <= READ_STORE;
	end
endtask

task read_rom_store;
	begin				
		//$display("storing result");
		data_nibble = rom_nibble;
		//$display("PC: %h | read => %h", PC, rom_nibble);
		PC = PC + 1;
		rom_enable = 1'b0;
		rom_clock = 1'b0;
		read_state = READ_VALID;
	end
endtask

task read_rom;
	case (read_state)
		READ_START: read_rom_start();
		READ_CLOCK: read_rom_clock();
		READ_STORE: read_rom_store();
	endcase
endtask	

//--------------------------------------------------------------------------------------------------
//
// INSTRUCTION DECODING
//
//--------------------------------------------------------------------------------------------------


task run_nibble_start;
	case (read_state)
		READ_START:	
			begin
				read_rom();
				saved_PC <= PC;
			end
		READ_CLOCK, READ_STORE:
			read_rom();
		READ_VALID:
			run_state <= RUN_DECODE;
	endcase;
endtask

task run_nibble;
	begin
		if ((run_state == RUN_START) & (read_state == READ_START) & (decode_state == DECODE_START))
			display_registers();
		case (run_state)
			RUN_START:run_nibble_start();
			RUN_DECODE: instruction_decoder();
		endcase
	end
endtask

task instruction_decoder_start;
	case (data_nibble)
		4'h0 : decode_0();
		4'h1 : decode_1();
		4'h2 : inst_p_equals();
		4'h3 : inst_lc();

		4'h6 : inst_goto();
		4'h8 : decode_8();

		default: 
			begin
				$display("%05h nibble %h => unimplemented", saved_PC, data_nibble);
				halt_processor();
			end
	endcase
endtask

task instruction_decoder_unhandled;
	begin
		$display("unhandled state %h last nibble %h", decode_state, data_nibble);
		halt_processor();
	end
endtask

task instruction_decoder;
	case (decode_state)
		DECODE_START:				instruction_decoder_start();
		// instruction specific stuff
		DECODE_0, DECODE_0X:			decode_0();
		DECODE_1, DECODE_1X:			decode_1();
		DECODE_D0_EQ_5N:				inst_d0_eq_5n();
		DECODE_P_EQ:					inst_p_equals();
		DECODE_LC_LEN, DECODE_LC:		inst_lc(); 
		DECODE_GOTO:					inst_goto();
		DECODE_8, DECODE_8X:			decode_8();
		DECODE_80:						decode_80();
		DECODE_C_EQ_P_N:				inst_c_eq_p_n();
		DECODE_82:						decode_82();
		DECODE_ST_EQ_0_N:				inst_st_eq_0_n();
		DECODE_ST_EQ_1_N:				inst_st_eq_1_n();
		DECODE_GOVLNG, DECODE_GOSBVL:	inst_govlng_gosbvl();
		default: instruction_decoder_unhandled();
	endcase
endtask

task halt_processor;
	begin
		halt <= 1;
	end
endtask

task end_decode;
	begin
		read_state <= READ_START;
		run_state <= RUN_START;
		decode_state <= DECODE_START;
	end
endtask

task decode_0;
	case (decode_state)
		DECODE_START:
			begin
				decode_state <= DECODE_0X;
				read_state <= READ_START;
			end
		DECODE_0X:
			if (read_state != READ_VALID) read_rom();
			else decode_0x();
	endcase		
endtask

task decode_0x;
	case (data_nibble)
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
	case (decode_state)
		DECODE_START:
			begin
				decode_state = DECODE_1X;
				read_state = READ_START;
			end
		DECODE_1X:
			if (read_state != READ_VALID) read_rom();
			else decode_1x();
	endcase		
endtask

task decode_1x;
	case (data_nibble)
		4'hb:	 inst_d0_eq_5n();
		default: instruction_decoder_unhandled();
	endcase
endtask

// 1bnnnnn	DO=(5) nnnnn
task inst_d0_eq_5n;
	case (decode_state)
		DECODE_1X:
			begin
				decode_state = DECODE_D0_EQ_5N;
				read_state = READ_START;
				load_cnt = 4;
				load_ctr = 0;
				$write("%5h D0=(5)\t", saved_PC);
			end
		DECODE_D0_EQ_5N:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					D0[load_ctr*4+:4] = data_nibble;
					$write("%1h", data_nibble);
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

// 2n		P= n

task inst_p_equals;
	case (decode_state)
		DECODE_START:
			begin
				//$display("decoding \"P= n\" - reading from rom");
				decode_state <= DECODE_P_EQ;
				read_state <= READ_START;
			end
		DECODE_P_EQ:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					P <= data_nibble;	
					$display("%05h P=\t%h", saved_PC, data_nibble);	
					end_decode();
				end
		default:
			begin
				$display("unknown state while decoding \"P= n\" %d", decode_state);
				halt_processor();
			end
	endcase		
endtask

// 3nxxxxxxxxxxxxxxxx	LC xxxxxxxxxxxxxxxx
task inst_lc;
	case (decode_state)
		DECODE_START:
			begin
				decode_state = DECODE_LC_LEN;
				read_state = READ_START;
			end
		DECODE_LC_LEN:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					load_cnt = data_nibble;
					load_ctr = 0;
					decode_state = DECODE_LC;
					read_state = READ_START;
					$write("%5h LC (%h)\t", saved_PC, load_cnt);
				end
		DECODE_LC:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					C[((load_ctr+P)%16)*4+:4] = data_nibble;
					$write("%1h", data_nibble);
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

// 6zyx			GOTO	xyz
task inst_goto;
	case (decode_state)
		DECODE_START:
			begin
				decode_state <= DECODE_GOTO;
				read_state <= READ_START;
				jump_base <= PC;
				jump_offset <= 0;
				load_cnt = 2;
				load_ctr = 0;
				$write("%5h GOTO\t", saved_PC);
			end
		DECODE_GOTO:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					jump_offset[load_ctr*4+:4] = data_nibble;
					$write("%1h", data_nibble);
					if (load_ctr == load_cnt) 
						begin
							$display("\t=> %05h", jump_base + jump_offset);
							PC <= jump_base + jump_offset;
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

// 8x

task decode_8;
	case (decode_state)
		DECODE_START:
			begin
				decode_state <= DECODE_8X;
				read_state <= READ_START;
			end
		DECODE_8X:
			if (read_state != READ_VALID) read_rom();
			else decode_8x();
	endcase		
endtask

task decode_8x;
	case (data_nibble)
		4'h0: decode_80();
		4'h2: decode_82();
		4'h4: inst_st_eq_0_n();
		4'h5: inst_st_eq_1_n();
		4'hd,
		4'hf: inst_govlng_gosbvl();
		default: 
			begin
				$display("unhandled instruction prefix 8%h", data_nibble);
				halt_processor();
			end
	endcase
endtask

task decode_80;
	case (decode_state)
		DECODE_8X:
			begin
				decode_state <= DECODE_80;
				read_state <= READ_START;
			end
		DECODE_80:
			if (read_state != READ_VALID) read_rom();
			else
				case (data_nibble)
					4'h5:	inst_config();
					4'ha:   inst_reset();
					4'hc:	inst_c_eq_p_n();
					default:
						begin
							$display("decode_80: %h", data_nibble);
							halt_processor();
						end
				endcase
	endcase
endtask

// 805		CONFIG
task inst_config;
	begin
		$display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
		end_decode();
	end
endtask

// 80A		RESET
task inst_reset;
	begin
		$display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
		end_decode();
	end
endtask

// 80Cn		C=P	n
task inst_c_eq_p_n;
	case (decode_state)
		DECODE_80:
			begin
				decode_state <= DECODE_C_EQ_P_N;
				read_state <= READ_START;
			end
		DECODE_C_EQ_P_N:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					$display("%05h C=P\t%h", saved_PC, data_nibble);
					C[data_nibble*4+:4] <= P;
					end_decode();
				end
	endcase
endtask

task decode_82;
	case (decode_state)
		DECODE_8X:
			begin
				decode_state <= DECODE_82;
				read_state <= READ_START;
			end
		DECODE_82:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					HST <= HST & ~data_nibble;
					case (data_nibble)
						4'h1:	 $display("%5h XM=0", saved_PC);
						4'h2:	 $display("%5h SB=0", saved_PC);
						4'h4:    $display("%5h SR=0", saved_PC);
						4'h8:	 $display("%5h MP=0", saved_PC);
						4'hf:    $display("%5h CLRHST", saved_PC);
						default: $display("%5h CLRHST	%f", saved_PC, data_nibble);
					endcase
					end_decode();
				end
	endcase
endtask

// 84n		ST=0	n
task inst_st_eq_0_n;
	case (decode_state)
		DECODE_8X:
			begin
				decode_state <= DECODE_ST_EQ_0_N;
				read_state <= READ_START;
			end
		DECODE_ST_EQ_0_N:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					$display("%05h ST=0\t%h", saved_PC, data_nibble);
					ST[data_nibble] <= 0;
					end_decode();
				end
	endcase
endtask

// 85n		ST=1	n
task inst_st_eq_1_n;
	case (decode_state)
		DECODE_8X:
			begin
				decode_state <= DECODE_ST_EQ_1_N;
				read_state <= READ_START;
			end
		DECODE_ST_EQ_1_N:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					$display("%05h ST=1\t%h", saved_PC, data_nibble);
					ST[data_nibble] <= 1;
					end_decode();
				end
	endcase
endtask

// 8Dzyxwv	GOVLNG	vwxyz
// 8Fzyxwv	GOSBVL	vwxyz
task inst_govlng_gosbvl;
	case (decode_state)
		DECODE_8X:
			begin
				read_state <= READ_START;
				jump_base <= 0;
				load_cnt <= 4;
				load_ctr <= 0;
				case (data_nibble)
					4'hD: 
						begin
							decode_state <= DECODE_GOVLNG;	
							$write("%5h GOVLNG\t", saved_PC);
						end				
					4'hF: 
						begin
							decode_state <= DECODE_GOSBVL;					
							$write("%5h GOSBVL\t", saved_PC);
						end
				endcase				
			end
		DECODE_GOVLNG, DECODE_GOSBVL:
			if (read_state != READ_VALID) read_rom();
			else
				begin
					jump_base[load_ctr*4+:4] = data_nibble;
					$write("%1h", data_nibble);
					if (load_ctr == load_cnt) 
						begin
							$display("\t=> %5h", jump_base);
							if (decode_state == DECODE_GOSBVL)
							begin
								rstk_ptr = rstk_ptr + 1;
								RSTK[rstk_ptr] = PC;							  
							end
							PC <= jump_base;
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

endmodule


`ifdef SIM

module rom_tb;
reg		clk;
reg		reset;
wire		halt;

saturn_core saturn (
	.clk	(clk),
	.reset	(reset),
	.halt	(halt)
);

always 
    #10 clk = (clk === 1'b0);

initial begin
	//$monitor ("clk %b | reset %b", clk, reset);
end 

initial begin
	clk <= 0;
	reset <= 1;
	$display("starting the simulation");
	@(posedge clk);
	@(negedge clk);
	reset <= 0;
	@(posedge halt);
	$finish;
end		


endmodule

`endif