/*
 * Licence: GPLv3 or later
 */

`default_nettype none //

/**************************************************************************************************
 *
 * Bus commands
 * 
 *
 *
 */

`define BUSCMD_NOP			0
`define BUSCMD_ID			1
`define BUSCMD_PC_READ		2
`define BUSCMD_DP_READ		3
`define BUSCMD_PC_WRITE		4	
`define BUSCMD_DP_WRITE		5
`define BUSCMD_LOAD_PC		6
`define BUSCMD_LOAD_DP		7
`define BUSCMD_CONFIGURE	8
`define BUSCMD_UNCONFIGURE	9
`define BUSCMD_RESET		15


/**************************************************************************************************
 *
 * Rom module
 * accesses the calculators firmware
 *
 *
 */

module hp_rom (
	input 				clk,
	input 		[19:0]	address,
	input		[3:0]	command,
	output	reg	[3:0]	nibble_out	
);
localparam 	ROM_FILENAME = "rom-gx-r.hex";

//
// This is only for debug, the rom should be stored elsewhere
//

`ifdef SIM
reg [3:0]	rom	[0:(2**20)-1];
`else
reg[3:0]	rom	[0:(2**16)-1];
`endif

reg [19:0]	pc_ptr;
reg [19:0]	data_ptr;

initial
begin
	$readmemh( ROM_FILENAME, rom);
end

always @(negedge clk)
		case (command)
			`BUSCMD_NOP: begin end				// do nothing	
			`BUSCMD_PC_READ:	
				begin
`ifdef SIM
					//$display("rom: PC_READ %5h => %h", address, rom[pc_ptr]);
`endif
					nibble_out <= rom[pc_ptr];
					pc_ptr <= pc_ptr + 1;
				end
			`BUSCMD_LOAD_PC:
				begin
`ifdef SIM
					//$display("rom: LOAD_PC %5h", address);
`endif
					pc_ptr <= address;
				end
			`BUSCMD_LOAD_DP:
				begin
`ifdef SIM
					//$display("rom: LOAD_DP %5h", address);
`endif
					data_ptr <= address;
				end
		endcase
endmodule

/**************************************************************************************************
 *
 * I/O ram 
 * length: 64 nibbles
 *
 *
 */


module hp48_io_ram (
	input			clk,
	input			reset,
	input	[19:0]	address,
	input	[3:0]	command,
	input	[3:0]	nibble_in,
	output	[3:0]	nibble_out,
	output	reg		io_ram_active,
	output	reg		io_ram_error
);

localparam IO_RAM_LEN		= 64;

// localparam BUSCMD_DP_WRITE	= C_BUSCMD_DP_WRITE;
// localparam BUSCMD_CONFIGURE = C_BUSCMD_CONFIGURE;


reg	[0:0]	configured;
reg [19:0]	base_addr;
reg [19:0]	pc_ptr;
reg [19:0]	data_ptr;
reg [3:0]	io_ram [0:IO_RAM_LEN-1];

/*
 *
 *
 */

initial
	begin
`ifdef SIM
		$display("io_ram: set unconfigured");
`endif
		configured = 0;
`ifdef SIM
		$display("io_ram: reset error flag");
`endif
		io_ram_error = 0;	
`ifdef SIM
		$display("io_ram: setting base address to 0");
`endif
		base_addr = 0;
`ifdef SIM
		$display("io_ram: setting data pointer to 0");
`endif
		data_ptr = 0;
`ifdef SIM
		$display("io_ram: initializing to 0");
`endif
		for (base_addr = 0; base_addr < IO_RAM_LEN; base_addr++)
			begin
`ifdef SIM
				$write(".");
`endif
				io_ram[base_addr] = 0; 
			end
`ifdef SIM	
		$display("");
		$display("io_ram: initialized");
`endif
	end

/*
 *
 *
 */

always @(*)
	case (command)
		`BUSCMD_PC_READ, `BUSCMD_PC_WRITE,
		`BUSCMD_DP_READ, `BUSCMD_DP_WRITE:
				io_ram_active = ((base_addr>=data_ptr)&(data_ptr<base_addr+IO_RAM_LEN))&(configured);
	endcase

always @(negedge clk)
	if ((~reset)&(~io_ram_error))
		case (command)
			`BUSCMD_NOP: begin end				// do nothing	
			`BUSCMD_PC_READ:	
				begin
				end
			`BUSCMD_DP_WRITE:
				begin
					// test if write can be done
					if (io_ram_active)
						begin
							io_ram[data_ptr - base_addr] <= nibble_in;
							data_ptr <= data_ptr + 1;
`ifdef SIM
							$display("io_ram: DP_WRITE %5h %h | OK", data_ptr, nibble_in); 
`endif
						end
`ifdef SIM
					else
							$display("io_ram: DP_WRITE %5h %h | NOK - IO_RAM not active (conf: %b)", data_ptr, nibble_in, configured); 
`endif
				end
			`BUSCMD_LOAD_PC:
				begin
`ifdef SIM
					//$display("io_ram: LOAD_PC %5h", address);
`endif
					pc_ptr <= address;
				end
			`BUSCMD_LOAD_DP:
				begin
`ifdef SIM
					//$display("io_ram: LOAD_DP %5h", address);
`endif
					data_ptr <= address;
				end
			`BUSCMD_CONFIGURE:
				begin
`ifdef SIM
					$display("io_ram: configure at %5h len %d", address, IO_RAM_LEN);
`endif
					base_addr <= address;
					configured <= 1;
				end
			default:
				begin
`ifdef SIM
					$display("io_ram: unhandled command %h", command);
`endif
					io_ram_error <= 1;
				end
		endcase

endmodule

/**************************************************************************************************
 *
 *  Bus manager
 *
 *
 *
 */

module hp48_bus (
	input					clk,
	input					reset,
	input			[19:0]	address,
	input			[3:0]	command,
	input			[3:0]	nibble_in,
	output	reg		[3:0]	nibble_out,
	output	reg					bus_error
);

// io_ram
wire [3:0]	io_ram_nibble_out;
wire		io_ram_active;
wire		io_ram_error;

// rom
wire [3:0]	rom_nibble_out;

//
// listed in order of priority
//
hp48_io_ram io_ram (
	.clk			(clk),
	.reset			(reset),
	.address		(address),
	.command		(command),
	.nibble_in		(nibble_in),
	.nibble_out		(io_ram_nibble_out),
	.io_ram_active	(io_ram_active),
	.io_ram_error	(io_ram_error)
);

hp_rom calc_rom (
	.clk			(clk),
	.address		(address),
	.command		(command),
	.nibble_out		(rom_nibble_out)
);


always @(*)
	begin
		case (command)
			`BUSCMD_PC_READ, `BUSCMD_DP_READ:
				begin
					if (io_ram_active) nibble_out <= io_ram_nibble_out;	
					if (~io_ram_active) nibble_out <= rom_nibble_out;
				end
		endcase
		bus_error <= io_ram_error;
	end

endmodule



/**************************************************************************************************
 *
 *
 *
 *
 *
 */
`ifdef SIM
module saturn_core (
	input			clk,
	input			reset,
	output			halt,
	output [3:0] 	runstate,
	output [15:0] 	decstate
);
`else
module saturn_core (
	input			clk_25mhz,
	input [6:0] 	btn,
	output 			wifi_gpio0,
	output [7:0]	led
);
wire 		clk;
wire 		reset;

assign wifi_gpio0	= 1'b1;
assign clk			= clk_25mhz;
assign reset		= btn[1];

`endif

// led display states
localparam	REGDMP_HEX		= 8'h00;


// bus commands

// localparam BUSCMD_DP_WRITE	= `C_BUSCMD_DP_WRITE;
// localparam BUSCMD_CONFIGURE = `C_BUSCMD_CONFIGURE;

// runstate

localparam RUN_START	= 0;
localparam READ_ROM_STA	= 1;
localparam READ_ROM_CLK	= 2;
localparam READ_ROM_STR	= 3;
localparam READ_ROM_VAL	= 4;
localparam WRITE_STA	= 5;
localparam WRITE_STROBE	= 6;
localparam WRITE_DONE	= 8;
localparam RUN_EXEC		= 14;
localparam RUN_DECODE	= 15;

// instruction decoder states

localparam DECODE_START		= 16'h0000;

localparam DECODE_0			= 16'h0001;
localparam DECODE_0X		= 16'h0002;

localparam DECODE_RTNCC		= 16'h0300;
localparam DECODE_SETHEX	= 16'h0400;
localparam DECODE_SETDEC	= 16'h0500;

localparam DECODE_1			= 16'h0010;
localparam DECODE_1X		= 16'h0011;
localparam DECODE_14		= 16'h0410;
localparam DECODE_15		= 16'h0510;
localparam DECODE_MEMACCESS	= 16'h0411;
localparam DECODE_D0_EQ_5N	= 16'h0b10;

localparam DECODE_P_EQ		= 16'h0020;

localparam DECODE_LC_LEN	= 16'h0030;
localparam DECODE_LC		= 16'h0031;

localparam DECODE_GOTO		= 16'h0060;

localparam DECODE_8			= 16'h0080;
localparam DECODE_8X		= 16'h0081;
localparam DECODE_80		= 16'h0082;

localparam DECODE_CONFIG	= 16'h5080;
localparam DECODE_RESET		= 16'hA080;

localparam DECODE_C_EQ_P_N	= 16'hC080;

localparam DECODE_82		= 16'h0280;

localparam DECODE_ST_EQ_0_N	= 16'h0480;
localparam DECODE_ST_EQ_1_N	= 16'h0580;

localparam DECODE_GOVLNG	= 16'h0d80;
localparam DECODE_GOSBVL	= 16'h0f80;

localparam DECODE_A			= 16'h00a0;
localparam DECODE_A_FS		= 16'h00a1;

// status registers constants

localparam HEX			= 0;
localparam DEC			= 1;

// data transfer constants

localparam T_DIR_OUT	= 0;
localparam T_DIR_IN		= 1;
localparam T_PTR_0		= 0;
localparam T_PTR_1		= 1;
localparam T_REG_A		= 0;
localparam T_REG_C		= 1;
localparam T_FIELD_P	= 0;
localparam T_FIELD_WP	= 1;
localparam T_FIELD_XS	= 2;
localparam T_FIELD_X	= 3;
localparam T_FIELD_S	= 4;
localparam T_FIELD_M	= 5;
localparam T_FIELD_B	= 6;
localparam T_FIELD_W	= 7;
localparam T_FIELD_LEN	= 13;
localparam T_FIELD_A	= 15;

// state machine stuff
reg				halt;
reg		[3:0]	runstate;
reg		[15:0]	decstate;
reg		[7:0]	regdump;

// bus access
reg		[19:0]	bus_address;
reg		[3:0]	bus_command;
reg		[3:0]	bus_nibble_in;
wire	[3:0]	bus_nibble_out;
wire			bus_error;

// should go away, the rom should work like any other bus module
reg				rom_enable;

// internal registers
reg	[3:0]	nibble;
reg	[19:0]  saved_PC;
reg	[2:0]	rstk_ptr;
reg	[19:0]  jump_base;
reg	[19:0]	jump_offset;
reg			hex_dec;

// data transfer registers
reg [3:0]	t_offset;
reg	[3:0]	t_cnt;
reg	[3:0]	t_ctr;
reg 		t_dir;
reg			t_ptr;
reg			t_reg;
reg	[3:0]	t_field;

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

hp48_bus bus_ctrl (
	.clk			(clk),
	.reset			(reset),
	.address		(bus_address),
	.command		(bus_command),
	.nibble_in		(bus_nibble_in),
	.nibble_out		(bus_nibble_out),
	.bus_error		(bus_error)
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
			// bus

			bus_command <= `BUSCMD_NOP;
			
			// processor state machine
			
			halt		<= 0;
			runstate	<= RUN_START;
			decstate 	<= DECODE_START;
			regdump		<= REGDMP_HEX;

 			// processor registers

			hex_dec		<= HEX;
			rstk_ptr	<= 7;

			PC			<= 0;
			saved_PC	<= 0;
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
						
		end
	else
		if (runstate == RUN_START) 
			runstate <= READ_ROM_STA;

	if (bus_error)
		begin	
			halt <= 1;
		end

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
			bus_address <= PC;
			bus_command <= `BUSCMD_LOAD_PC;
			runstate <= READ_ROM_CLK;
		end

// read from rom clock in
	if (runstate == READ_ROM_CLK)
		begin				
			//$display("READ_ROM_CLK");
			bus_command <= `BUSCMD_PC_READ;
			runstate <= READ_ROM_STR;
		end

// read from rom store
	if (runstate == READ_ROM_STR)
		begin				
			//$display("READ_ROM_STR");
			bus_command <= `BUSCMD_NOP;
			nibble <= bus_nibble_out;
			//$display("PC: %h | read => %h", PC, bus_nibble_out);
			PC <= PC + 1;
			rom_enable <= 1'b0;
//			rom_clock <= 1'b0;
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
						halt <= 1;
					end
			endcase
		end

/******************************************************************************
 * 0X			
 *
 *
 */ 

	if (decstate == DECODE_0)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				case (nibble)
					4'h3: decstate <= DECODE_RTNCC;
					4'h4: decstate <= DECODE_SETHEX;
					4'h5: decstate <= DECODE_SETDEC;
					
					default: 
						begin
`ifdef SIM
							$display("%05h 0%h => unimplemented", saved_PC, nibble);
`endif
							halt <= 1;
						end
				endcase
			default: 
				begin
`ifdef SIM
					$display("DECODE_0 runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 * 03			RTNCC
 *
 *
 */ 

	if (decstate == DECODE_RTNCC)
		begin
			Carry <= 0;
			PC <= RSTK[rstk_ptr];
			RSTK[rstk_ptr] <= 0;		
			rstk_ptr <= rstk_ptr - 1;
`ifdef SIM
			$display("%05h RTNCC", saved_PC);
`endif
			runstate <= RUN_START;
			decstate <= DECODE_START;
		end

/******************************************************************************
 * 04			SETHEX
 *
 *
 */ 

	if (decstate == DECODE_SETHEX)
		begin
			hex_dec <= HEX;
`ifdef SIM
			$display("%05h SETHEX", saved_PC);
`endif
			runstate <= RUN_START;
			decstate <= DECODE_START;
		end

/******************************************************************************
 * 05			SETDEC
 *
 *
 */ 

	if (decstate == DECODE_SETDEC)
		begin
			hex_dec <= DEC;
`ifdef SIM
			$display("%05h SETDEC", saved_PC);
`endif
			runstate <= RUN_START;
			decstate <= DECODE_START;
		end

/******************************************************************************
 * 1X
 *
 *
 */ 

	if (decstate == DECODE_1)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					case (nibble)
						//4'h4, 4'h5:	decode_14_15();
						4'h4:	decstate <= DECODE_14;
						4'hb:	decstate <= DECODE_D0_EQ_5N;
						default:
							begin
`ifdef SIM
								$display("unhandled instruction prefix 1%h", nibble);
`endif
								halt <= 1;
							end
					endcase
					runstate <= RUN_DECODE;
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

	if ((decstate == DECODE_14)|(decstate == DECODE_15))
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				case (decstate)
					DECODE_14:
						begin
`ifdef SIM
							$display("14%h ", nibble);
`endif
							t_ptr <= nibble[0];
							t_dir <= nibble[1];
							t_reg <= nibble[2];
							if (~nibble[3]) t_field <= T_FIELD_A;
							else t_field <= T_FIELD_B;
							decstate <= DECODE_MEMACCESS;
							runstate <= RUN_EXEC;
						end
					default:
						begin
`ifdef SIM
							$display("15%h UNIMPLEMENTED", nibble);
`endif
							halt <= 1;
						end
				endcase
			default: 
				begin
`ifdef SIM
					$display("runstate %h", decstate);
`endif
					halt <= 1;
				end
		endcase

	if (decstate == DECODE_MEMACCESS)
		case (runstate)
			RUN_EXEC:
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
						T_DIR_OUT: runstate <= WRITE_STA;
						T_DIR_IN:  runstate <= READ_ROM_STA;
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
			WRITE_STA:
				begin
`ifdef SIM
					$display("WRITE_STA    | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
							 t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_field, t_offset, t_ctr, t_cnt);
`endif
					bus_command <= `BUSCMD_LOAD_DP;
					bus_address <= (~t_ptr)?D0:D1;
					runstate <= WRITE_STROBE;
				end
			WRITE_STROBE:
				begin
`ifdef SIM
					$display("WRITE_STROBE | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
							 t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_offset, t_ctr, t_cnt);
`endif
					bus_command <= `BUSCMD_DP_WRITE;
					bus_nibble_in <= (~t_reg)?A[t_offset*4+:4]:C[t_offset*4+:4];
					t_offset <= t_offset + 1;
					t_ctr <= t_ctr + 1;
					if (t_ctr == t_cnt)
						begin
							runstate <= WRITE_DONE;
						end
				end
			WRITE_DONE:
				begin
`ifdef SIM
					$display("WRITE_DONE   | ptr %s | dir %s | reg %s | field %h | off %h | ctr %h | cnt %h", 
							 t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field, t_offset, t_ctr, t_cnt);
`endif
					bus_command <= `BUSCMD_NOP;
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default: 
				begin
`ifdef SIM
					$display("runstate %h | decstate %h | ptr %s | dir %s | reg %s | field %h", 
							 runstate, decstate, t_ptr?"D1":"D0", t_dir?"IN":"OUT", t_reg?"C":"A", t_field);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 *1bnnnnn		DO=(5) nnnnn
 *
 *
 */ 

	if (decstate == DECODE_D0_EQ_5N)
		case (runstate)
			RUN_DECODE:
				begin
					runstate <= READ_ROM_STA;
					t_cnt <= 4;
					t_ctr <= 0;
`ifdef SIM
					$write("%5h D0=(5)\t", saved_PC);
`endif
				end
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					D0[t_ctr*4+:4] <= nibble;
`ifdef SIM
					$write("%1h", nibble);
`endif
					if (t_ctr == t_cnt)
						begin
`ifdef SIM
							$display("");
`endif
							runstate <= RUN_START;
							decstate <= DECODE_START;
						end
					else 
						begin 
							t_ctr <= t_ctr + 1;
							runstate <= READ_ROM_STA;
						end
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
 * 2n			P= 		n
 *
 *
 */ 
 
	if (decstate == DECODE_P_EQ)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
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


/******************************************************************************
 * 3n[xxxxxx]	LC (n) [xxxxxx]
 *
 *
 */ 
 
	if ((decstate == DECODE_LC_LEN) | (decstate == DECODE_LC))
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				case (decstate)
					DECODE_LC_LEN:
						begin
`ifdef SIM
							$write("%5h LC (%h)\t", saved_PC, nibble);
`endif
							t_cnt <= nibble;
							t_ctr <= 0;
							decstate <= DECODE_LC;
							runstate <= READ_ROM_STA;
						end
					DECODE_LC:
						begin
							C[((t_ctr+P)%16)*4+:4] <= nibble;
`ifdef SIM
							$write("%1h", nibble);
`endif
							if (t_ctr == t_cnt) 
								begin
`ifdef SIM
									$display("");
`endif
									runstate <= RUN_START;
									decstate <= DECODE_START;
									
								end 
							else 
								begin 
									t_ctr <= (t_ctr + 1)&4'hf;
									runstate <= READ_ROM_STA;
								end							
						end
					default:
						begin
`ifdef SIM
							$display("decstate %h nibble %h", decstate, nibble);
`endif
							halt <= 1;
						end
				endcase
			default:
				begin
`ifdef SIM
					$display("DECODE_LC decstate %h", decstate);
`endif
					halt <= 1;
				end
		endcase

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
					t_cnt <= 2;
					t_ctr <= 0;
				end
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					jump_offset[t_ctr*4+:4] <= nibble;
					if (t_ctr == t_cnt) runstate <= RUN_EXEC;
					else 
						begin 
							t_ctr <= t_ctr + 1;
							runstate <= READ_ROM_STA;
						end
				end
			RUN_EXEC:
				begin
`ifdef SIM
					$display("%5h GOTO\t%3h\t=> %05h", saved_PC, jump_offset[11:0], jump_base + jump_offset);
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
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					case (nibble)
						4'h0: decstate <= DECODE_80;
						4'h2: decstate <= DECODE_82;
						4'h4: decstate <= DECODE_ST_EQ_0_N;
						4'h5: decstate <= DECODE_ST_EQ_1_N;
						4'hd: decstate <= DECODE_GOVLNG;
						4'hf: decstate <= DECODE_GOSBVL;
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
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					case (nibble)
						4'h5:   decstate <= DECODE_CONFIG;
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

/******************************************************************************
 * 805		CONFIG
 *
 *
 */ 

	if ((decstate == DECODE_CONFIG) & (runstate == RUN_DECODE))	
		begin
`ifdef SIM
			$display("%05h CONFIG\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
`endif
			runstate <= RUN_START;
			decstate <= DECODE_START;
		end

/******************************************************************************
 * 80A		RESET
 *
 *
 */ 

	if ((decstate == DECODE_RESET) & (runstate == RUN_DECODE))	
		begin
`ifdef SIM
			$display("%05h RESET\t\t\t<= NOT IMPLEMENTED YET", saved_PC);
`endif
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
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
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


/******************************************************************************
 * 82x
 * 
 * lots of things there
 *
 */ 

	if (decstate == DECODE_82)
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
					HST <= HST & ~nibble;
`ifdef SIM
					case (nibble)
						4'h1:	 $display("%5h XM=0", saved_PC);
						4'h2:	 $display("%5h SB=0", saved_PC);
						4'h4:    $display("%5h SR=0", saved_PC);
						4'h8:	 $display("%5h MP=0", saved_PC);
						4'hf:    $display("%5h CLRHST", saved_PC);
						default: $display("%5h CLRHST	%f", saved_PC, nibble);
					endcase
`endif
					runstate <= RUN_START;
					decstate <= DECODE_START;
				end
			default: 
				begin
`ifdef SIM
					$display("DECODE_82 runstate %h", runstate);
`endif
					halt <= 1;
				end
		endcase

/******************************************************************************
 * 84n	ST=0   n
 * 85n	ST=1   n
 */ 

	if ((decstate == DECODE_ST_EQ_0_N) | (decstate == DECODE_ST_EQ_1_N))
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
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
					t_cnt <= 4;
					t_ctr <= 0;
					if (decstate == DECODE_GOSBVL)
						rstk_ptr <= rstk_ptr + 1;
					runstate <= READ_ROM_STA;
				end
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				begin
				  //$display("decstate %h | nibble %h", decstate, nibble);
				  jump_base[t_ctr*4+:4] <= nibble;
				  if (t_ctr == t_cnt) runstate <= RUN_EXEC;
					else 
						begin 
							t_ctr <= t_ctr + 1;
							runstate <= READ_ROM_STA;
						end
				end
			RUN_EXEC:
				begin
`ifdef SIM
					$write("%5h GO", saved_PC);
					case (decstate)
						DECODE_GOVLNG: $write("VLNG");
						DECODE_GOSBVL: $write("SBVL");
					endcase
					$display("\t%5h", jump_base);
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

/******************************************************************************
 * A[ab]x
 * 
 * lots of things there
 *
 */ 

	if ((decstate == DECODE_A)|(decstate == DECODE_A_FS))
		case (runstate)
			RUN_DECODE: runstate <= READ_ROM_STA;
			READ_ROM_STA, READ_ROM_CLK, READ_ROM_STR: begin end
			READ_ROM_VAL:
				case (decstate)
					DECODE_A: 
						begin
							t_field <= nibble;
							decstate <= DECODE_A_FS;
							runstate <= READ_ROM_STA;
						end
					DECODE_A_FS: 
						begin				
							case (nibble)
								4'h2:
									case (t_field)
										4'he: 
											begin
												C[7:0] <= 0;
`ifdef SIM
												$display("%5h C=0\tB", saved_PC);
`endif
											end
									endcase
								default:
									begin
`ifdef SIM
										$display("decstate %h %h %h", decstate, t_field, nibble);
`endif
										halt <= 1;
									end
							endcase
							runstate <= RUN_START;
							decstate <= DECODE_START;
						end
					default:
						begin
`ifdef SIM
							$display("decstate %h %h", decstate, nibble);
`endif
							halt <= 1;
						end
				endcase
			default:
				begin
`ifdef SIM
					$display("decstate %h", decstate);
`endif
					halt <= 1;
				end
		endcase

/**************************************************************************************************
 *
 * Dump all registers to leds, one piece at a time
 *
 */

`ifndef SIM

	case (regdump)
		REGDMP_HEX:	led <= {7'b0000000, hex_dec};
		default: led <= 8'b11111111;
	endcase
	regdump <= regdump + 1;
	
`endif

end
// Verilator lint_off UNUSED
//wire [N-1:0] unused;
//assign unused = { }; 
// Verilator lint_on UNUSED
endmodule

`ifdef SIM

module saturn_tb;
reg			clk;
reg			reset;
wire		halt;
wire [3:0]	runstate;
wire [15:0]	decstate;

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