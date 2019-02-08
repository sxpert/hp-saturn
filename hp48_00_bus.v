
`include "bus_commands.v"
`include "hp48_01_io_ram.v"
`include "hp48_02_sys_ram.v"
`include "hp48_06_rom.v"

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

// mmio
wire [3:0]	mmio_nibble_in;
wire [3:0]	mmio_nibble_out;
wire		mmio_active;
wire		mmio_daisy_in;
wire		mmio_daisy_out;
wire		mmio_error;

// sysram
wire [3:0]	sysram_nibble_in;
wire [3:0]	sysram_nibble_out;
wire		sysram_active;
wire		sysram_daisy_in;
wire		sysram_daisy_out;
wire		sysram_error;

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

assign mmio_nibble_in = nibble_in;
assign mmio_daisy_in = 1;

hp48_sys_ram dev_sys_ram (
	.strobe			(strobe),
	.reset			(reset),
	.address		(address),
	.command		(command),
	.nibble_in		(sysram_nibble_in),
	.nibble_out		(sysram_nibble_out),
	.active			(sysram_active),
	.daisy_in		(sysram_daisy_in),
	.daisy_out		(sysram_daisy_out),
	.error			(sysram_error)
);

assign sysram_nibble_in = nibble_in;
assign sysram_daisy_in = mmio_daisy_out;


hp48_rom dev_rom (
	.strobe 			(strobe),
	.address			(address),
	.command			(command),
	.nibble_out			(rom_nibble_out)
);


always @(*)
	begin
		bus_error = mmio_error;
		if (strobe & mmio_active) nibble_out = mmio_nibble_out;
		if (strobe & (!mmio_active & sysram_active)) nibble_out = sysram_nibble_out;
		if (strobe & (!mmio_active & !sysram_active)) nibble_out = rom_nibble_out;
	end

endmodule

`endif
