`include "bus_commands.v"

`ifndef _HP48_SYS_RAM
`define _HP48_SYS_RAM

/**************************************************************************************************
 *
 * I/O ram 
 * length: 64 nibbles
 *
 *
 */


module hp48_sys_ram (
	input				strobe,
	input				reset,
	input		[19:0]	address,
	input		[3:0]	command,
	input		[3:0]	nibble_in,
	output	reg [3:0]	nibble_out,
	output	   			active,
	input				daisy_in,
	output  			daisy_out,
	output	reg			error
);

`ifdef SIM
localparam SYS_RAM_LEN		= 262144;
`else
localparam SYS_RAM_LEN		= 65536;
`endif

reg	    [0:0]	addr_conf;
reg     [0:0]   len_conf;
reg     [19:0]	base_addr;
reg     [19:0]  length;
reg     [19:0]  last_addr;
reg     [19:0]	pc_ptr;
reg     [19:0]	dp_ptr;
reg     [3:0]	sys_ram [0:SYS_RAM_LEN - 1];
wire            configured;

assign daisy_out = addr_conf & len_conf;
assign configured = daisy_out;
/*
 *
 *
 */

initial
	begin
`ifdef SIM
		$display("sys_ram: set unconfigured");
`endif
		addr_conf = 0;
        len_conf = 0;
`ifdef SIM
		$display("sys_ram: reset error flag");
`endif
		error = 0;	
`ifdef SIM
        // initialize only in simulation
		$display("sys_ram: initializing to 0");
		for (base_addr = 0; base_addr < SYS_RAM_LEN; base_addr++)
			begin
				sys_ram[base_addr] <= 0; 
			end
		$display("sys_ram: setting pc and data pointers to 0");
`endif
        pc_ptr = 0;
		dp_ptr = 0;
`ifdef SIM
		$display("sys_ram: setting base address to 0");
`endif
		base_addr = 0;
        length = 0;
`ifdef SIM	
		$write("\n");
		$display("sys_ram: initialized");
`endif
        // $monitor(">>>>>> SYSRAM CMD %h | CBPC %b | CBDP %b | %h %h %h %h | APC %b | ADP %b | CONF %b | ACT %b", 
        //          command, cmd_bus_pc, cmd_bus_dp, base_addr, last_addr, pc_ptr, dp_ptr, 
        //          active_pc_ptr, active_dp_ptr, configured, active);
	end

/*
 *
 *
 */


// PC_PTR tests
wire            cmd_bus_pc;
wire [19:0]     b_addr_minus_pc_ptr;
wire            b_addr_infeq_pc_ptr;
wire [19:0]     pc_ptr_minus_l_addr;
wire            pc_ptr_inf_l_addr;
wire            active_pc_ptr;

assign cmd_bus_pc = (command == `BUSCMD_PC_READ) | (command == `BUSCMD_PC_WRITE);
assign {b_addr_infeq_pc_ptr, b_addr_minus_pc_ptr} = base_addr - pc_ptr - 1;
assign {pc_ptr_inf_l_addr, pc_ptr_minus_l_addr} = pc_ptr - last_addr - 1;
assign active_pc_ptr = cmd_bus_pc & b_addr_infeq_pc_ptr & pc_ptr_inf_l_addr;

// PC_PTR tests
wire            cmd_bus_dp;
wire [19:0]     b_addr_minus_dp_ptr;
wire            b_addr_infeq_dp_ptr;
wire [19:0]     dp_ptr_minus_l_addr;
wire            dp_ptr_inf_l_addr;
wire            active_dp_ptr;

assign cmd_bus_dp = (command == `BUSCMD_DP_READ) | (command == `BUSCMD_DP_WRITE);
assign {b_addr_infeq_dp_ptr, b_addr_minus_dp_ptr} = base_addr - dp_ptr - 1;
assign {dp_ptr_inf_l_addr, dp_ptr_minus_l_addr} = dp_ptr - last_addr - 1;
assign active_dp_ptr = cmd_bus_dp & b_addr_infeq_dp_ptr & dp_ptr_inf_l_addr;

// global
wire            cmd_read;
wire            cmd_write;

assign cmd_read = (command == `BUSCMD_PC_READ) | (command == `BUSCMD_DP_WRITE);
assign cmd_write = (command == `BUSCMD_DP_WRITE) | (command == `BUSCMD_PC_WRITE);

assign active = (active_pc_ptr | active_dp_ptr) & configured;

always @(posedge strobe) begin
    
    // read from ram

    if (configured & cmd_read)
        nibble_out <= sys_ram[(cmd_bus_dp?dp_ptr:pc_ptr) - base_addr];
    
    // write to ram

    if (configured & cmd_write)
        sys_ram[(cmd_bus_dp?dp_ptr:pc_ptr) - base_addr] <= nibble_in;


	case (command)
	`BUSCMD_PC_READ, `BUSCMD_PC_WRITE: begin
		pc_ptr <= pc_ptr + 1;
	end
	`BUSCMD_DP_READ, `BUSCMD_DP_WRITE: begin
		dp_ptr <= dp_ptr + 1;
	end
	`BUSCMD_LOAD_PC: begin
		pc_ptr <= address;
		// $display("SYSRAM (%b - %5h %5h) - LOAD_PC %5h", configured, base_addr, length, address);
	end
	`BUSCMD_LOAD_DP: begin
		dp_ptr <= address;
		// $display("SYSRAM (%b - %5h %5h) - LOAD_DP %5h", configured, base_addr, length, address);
	end
	`BUSCMD_CONFIGURE: begin
		if (!configured) begin
            if (daisy_in) begin
                if (!len_conf & !addr_conf) begin
                    length <= (21'h100000 - { 1'b0, address});
                    len_conf <= 1;
                    $display("SYSRAM (%b - %5h %5h) - CONFIGURE LENGTH %5h", configured, base_addr, (21'h100000 - { 1'b0, address}), address);
                end
                if (len_conf & !addr_conf) begin
                    base_addr <= address;
                    addr_conf <= 1;
                    last_addr <= address + length - 1;
                    $display("SYSRAM (%b - %5h %5h) - CONFIGURE ADDRESS %5h", configured, address, length, address);
                end
            end else begin
    			$display("SYSRAM (%b - %5h %5h) - CAN'T CONFIGURE - DAISY_IN NOT SET %5h", configured, base_addr, length, address);
            end
		end else begin
			$display("SYSRAM (%b - %5h %5h) - ALREADY CONFIGURED %5h", configured, base_addr, length, address);
		end
	end
	`BUSCMD_RESET: begin
		base_addr <= 0;
        length <= 0;
		addr_conf <= 0;
        len_conf <= 0;
		$display("SYSRAM (%b - %5h %5h) - RESET", configured, base_addr, length);
	end
	default: begin
		$display("SYSRAM (%b - %5h %5h) - UNIMPLEMENTED COMMAND %d %5h", configured, base_addr, length, command, address);
		error <= 1;
	end
	endcase      
end

endmodule

`endif
