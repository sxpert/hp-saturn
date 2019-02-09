`include "bus_commands.v"

`ifndef _HP48_IO_RAM
`define _HP48_IO_RAM

/**************************************************************************************************
 *
 * I/O ram 
 * length: 64 nibbles
 *
 *
 */


module hp48_io_ram (
	input				strobe,
	input				reset,
	input		[19:0]	address,
	input		[3:0]	command,
	input		[3:0]	nibble_in,
	output	reg [3:0]	nibble_out,
	output	reg			active,
	input				daisy_in,
	output  			daisy_out,
	output	reg			error
);

localparam IO_RAM_LEN		= 64;

// localparam BUSCMD_DP_WRITE	= C_BUSCMD_DP_WRITE;
// localparam BUSCMD_CONFIGURE = C_BUSCMD_CONFIGURE;


reg	[0:0]	configured;
reg [19:0]	base_addr;
reg [19:0]	pc_ptr;
reg [19:0]	dp_ptr;
reg [3:0]	mmio_ram [0:IO_RAM_LEN-1];

assign daisy_out = configured;

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
		error = 1'b0;	
`ifdef SIM
		$display("io_ram: setting data pointer to 0");
`endif
		dp_ptr = 0;
`ifdef SIM
		// initialization only for simulation
		$display("io_ram: initializing to 0");
		for (base_addr = 0; base_addr < IO_RAM_LEN; base_addr++)
			begin
				$write(".");
				mmio_ram[base_addr] = 0; 
			end
		$display("io_ram: setting base address to 0");
`endif
		base_addr = 0;

`ifdef SIM	
		$write("\n");
		$display("io_ram: initialized");
`endif
	end

/*
 *
 *
 */
wire            cmd_bus_pc;
wire            cmd_bus_dp;
wire            cmd_read;
wire            cmd_write;

assign cmd_bus_pc = (command == `BUSCMD_PC_READ) | (command == `BUSCMD_PC_WRITE);
assign cmd_bus_dp = (command == `BUSCMD_DP_READ) | (command == `BUSCMD_DP_WRITE);
assign cmd_read = (command == `BUSCMD_PC_READ) | (command == `BUSCMD_DP_WRITE);
assign cmd_write = (command == `BUSCMD_DP_WRITE) | (command == `BUSCMD_PC_WRITE);

always @(*)
	begin
		active = 0;

		if ((command==`BUSCMD_PC_READ)|(command==`BUSCMD_PC_WRITE))
			active = ((base_addr>=pc_ptr)&(pc_ptr<base_addr+IO_RAM_LEN))&(configured);
		
		if ((command==`BUSCMD_DP_READ)|(command==`BUSCMD_DP_WRITE))
			active = ((base_addr>=dp_ptr)&(dp_ptr<base_addr+IO_RAM_LEN))&(configured);
	end


always @(posedge strobe) begin
    
    // read from ram

    if (configured & cmd_read)
        nibble_out <= mmio_ram[(cmd_bus_dp?dp_ptr:pc_ptr) - base_addr];
end    

always @(posedge strobe) begin
    // write to ram

    if (configured & cmd_write)
        mmio_ram[(cmd_bus_dp?dp_ptr:pc_ptr) - base_addr] <= nibble_in;
end


always @(posedge strobe) begin
	case (command)
	`BUSCMD_PC_READ: begin
		pc_ptr <= pc_ptr + 1;
	end
	`BUSCMD_DP_READ, `BUSCMD_DP_WRITE: begin
		dp_ptr <= dp_ptr + 1;
	end
	`BUSCMD_LOAD_PC: begin
		// $display("MMIO (%b - %5h) - LOAD_PC %5h", configured, base_addr, address);
		pc_ptr <= address;
	end
	`BUSCMD_LOAD_DP: begin
		dp_ptr <= address;
		// $display("MMIO (%b - %5h) - LOAD_DP %5h", configured, base_addr, address);
	end
	`BUSCMD_CONFIGURE: begin
		if (!configured) begin
			if (daisy_in) begin
				base_addr <= address;
				configured <= 1;
				// $display("MMIO (%b - %5h) - CONFIGURE %5h", configured, base_addr, address);
			end else begin
    			$display("MMIO (%b - %5h) - CAN'T CONFIGURE - DAISY_IN NOT SET %5h", configured, base_addr, address);
			end
		end else begin
			// $display("MMIO (%b - %5h) - ALREADY CONFIGURED %5h", configured, base_addr, address);
		end
	end
	`BUSCMD_RESET: begin
		base_addr <= 0;
		configured <= 0;
		$display("MMIO (%b - %5h) - RESET", configured, base_addr);
	end
	default: begin
		$display("MMIO (%b - %5h) - UNIMPLEMENTED COMMAND %d %5h", configured, base_addr, command, address);
		error <= 1;
	end
	endcase      
end

endmodule

`endif
