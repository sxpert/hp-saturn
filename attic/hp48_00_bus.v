`define MMIO
`define SYSRAM

`include "bus_commands.v"

`ifdef MMIO
`include "hp48_01_io_ram.v"
`endif

`ifdef SYSRAM
`include "hp48_02_sys_ram.v"
`endif

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
	output			[3:0]	nibble_out,
	output					bus_error
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


`ifdef MMIO

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

`else

assign mmio_error = 0;
assign mmio_active = 0;
assign mmio_nibble_out = 0;
assign mmio_error = 0;

`endif

`ifdef SYSRAM

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

`else

assign sysram_active = 0;
assign sysram_nibble_out = 0;
assign sysram_error = 0;

`endif

hp48_rom dev_rom (
	.strobe 			(strobe),
	.address			(address),
	.command			(command),
	.nibble_out			(rom_nibble_out)
);


assign bus_error = mmio_error | sysram_error;

wire show_mmio;
wire show_sysram;
wire show_rom;

assign show_mmio = mmio_active;
assign show_sysram = !mmio_active & sysram_active;
assign show_rom = !mmio_active & !sysram_active;

assign nibble_out = {4 {strobe}} & (
					 ({4 {show_mmio}} & mmio_nibble_out) |
					 ({4 {show_sysram}} & sysram_nibble_out) |
					 ({4 {show_rom}} & rom_nibble_out));

// initial begin
// 	$monitor("BUS > STRB %b | MMIO %b %h | SYSRAM %b %h | ROM %b %h | IN %h | OUT %h",
// 			 strobe,
// 			 show_mmio, mmio_nibble_out, 
// 			 show_sysram, sysram_nibble_out, 
// 			 show_rom, rom_nibble_out,
// 			 nibble_in, nibble_out);
// end

endmodule

`endif
