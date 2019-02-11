`ifndef _SATURN_ALU
`define _SATURN_ALU

/**************************************************************************************************
 *
 *  Bus manager
 *
 *
 *
 */

module saturn_alu (
    // inputs
	input					strobe,
	input					reset,
	input			[19:0]	address,
	input			[3:0]	command,
	input			[3:0]	nibble_in,

    // outputs
	output			[3:0]	nibble_out,
	output					bus_error
);

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


endmodule

`endif