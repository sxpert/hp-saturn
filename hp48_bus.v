
`include "bus_commands.v"
`include "hp48_rom.v"
`include "hp48_io_ram.v"

`ifndef _HP48_BUS
`define _HP48_BUS

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
	output	reg				bus_error
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
hp48_io_ram dev_io_ram (
	.clk			(clk),
	.reset			(reset),
	.address		(address),
	.command		(command),
	.nibble_in		(nibble_in),
	.nibble_out		(io_ram_nibble_out),
	.io_ram_active	(io_ram_active),
	.io_ram_error	(io_ram_error)
);

hp48_rom dev_rom (
	.clk			(clk),
	.address		(address),
	.command		(command),
	.nibble_out		(rom_nibble_out)
);


always @(*)
	begin
		bus_error = io_ram_error;
		if ((command == `BUSCMD_PC_READ)|(command == `BUSCMD_DP_READ))
			begin
				if (io_ram_active) nibble_out = io_ram_nibble_out;	
				if (~io_ram_active) nibble_out = rom_nibble_out;
			end
        else
            begin
                nibble_out = 0;
            end 
	end

endmodule

`endif
