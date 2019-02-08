
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
	input					strobe,
	input					reset,
	input			[19:0]	address,
	input			[3:0]	command,
	input			[3:0]	nibble_in,
	output	reg		[3:0]	nibble_out,
	output	reg				bus_error
);

// io_ram
wire [3:0]	mmio_nibble_in;
wire [3:0]	mmio_nibble_out;
wire		mmio_active;
wire		mmio_daisy_in;
wire		mmio_daisy_out;
wire		mmio_error;

// rom
wire [3:0]	rom_nibble_out;

//
// listed in order of priority
//
hp48_io_ram dev_io_ram (
	.strobe			(strobe),
	.reset			(reset),
	.address		(address),
	.command		(command),
	.nibble_in		(mmio_nibble_in),
	.nibble_out		(mmio_nibble_out),
	.active			(mmio_active),
	.daisy_in		(mmio_daisy_in),
	.daisy_out		(mmio_daisy_out),
	.error			(mmio_error)
);

assign mmio_daisy_in = 1;
assign mmio_nibble_in = nibble_in;

hp48_rom dev_rom (
	.strobe 			(strobe),
	.address			(address),
	.command			(command),
	.nibble_out			(rom_nibble_out)
);


always @(*)
	begin
		bus_error = mmio_error;
		if (mmio_active) nibble_out = mmio_nibble_out;	
		if (!mmio_active) nibble_out = rom_nibble_out;
	end

endmodule

`endif
