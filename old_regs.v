reg		[31:0]	instr_ctr;
reg				decode_error;
reg				debug_stop;
reg		[3:0]	cycle_type;
reg		[3:0]	next_cycle;

reg 			read_next_pc;
reg				execute_cycle;
reg				inc_pc;
reg 			read_nibble;
reg				first_nibble;

reg		[11:0]	decstate;
reg		[11:0]	fields_return;
reg		[3:0]	regdump;

// bus access
reg		[19:0]	bus_address;
reg		[3:0]	bus_command;
reg		[3:0]	bus_nibble_in;
wire	[3:0]	bus_nibble_out;
wire			bus_error;
reg				bus_load_pc;
reg				en_bus_load_pc;

// should go away, the rom should work like any other bus module
reg		[7:0]   display_counter;

// internal registers
reg [19:0]	new_PC;
reg [19:0]	next_PC;
reg	[19:0]  inst_start_PC;

reg	[2:0]	rstk_ptr;

reg	[19:0]  jump_base;
reg	[19:0]	jump_offset;

reg			hex_dec;
`define	MODE_HEX	0;
`define MODE_DEC	1;

// data transfer registers
reg [3:0]	t_offset;
reg	[3:0]	t_cnt;
reg	[3:0]	t_ctr;
reg 		t_dir;
reg			t_ptr;
reg			t_reg;
reg			t_ftype;
reg	[3:0]	t_field;

reg	[3:0]	nb_in;
reg [3:0]	nb_out;
reg	[19:0]	add_out;

// temporary stuff
reg			t_set_test;
reg			t_set_test_val;
reg			t_add_sub;
reg	[3:0]	t_first;
reg [3:0]	t_last;

// alu control

reg	[3:0]	field;
reg [1:0]	field_table;

reg [4:0]	alu_op;
reg [3:0]	alu_first;
reg [3:0]	alu_last;
reg [3:0]	alu_const;
reg [3:0]	alu_reg_src1;
reg [3:0]	alu_reg_src2;
reg [3:0]	alu_reg_dest;

reg [3:0]	alu_src1;
reg [3:0]	alu_src2;
reg [3:0]	alu_res1;
reg [3:0]	alu_res2;
reg			alu_res_carry;
reg [3:0]	alu_tmp;
reg			alu_carry;
reg			alu_debug;
reg			alu_p1_halt;
reg			alu_p2_halt;
reg			alu_halt;
reg			alu_requested_halt;
reg	[11:0]	alu_return;
reg	[3:0]	alu_next_cycle;

// debugger registers
reg [19:0]	dbg_op_addr;
reg [15:0]	dbg_op_code;
reg [3:0]	dbg_reg_dest;
reg [3:0]	dbg_reg_src1;
reg [3:0]	dbg_reg_src2;
reg [3:0]	dbg_field;
reg [3:0]	dbg_first;
reg [3:0]	dbg_last;
reg [63:0]	dbg_data;

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
