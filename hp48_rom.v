
`include "bus_commands.v"

`ifndef _HP48_ROM
`define _HP48_ROM

/**************************************************************************************************
 *
 * Rom module
 * accesses the calculators firmware
 *
 *
 */

module hp48_rom (
	input 				strobe,
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

reg [3:0]	i_cmd;
reg [19:0]	pc_ptr;
reg [19:0]	data_ptr;

initial
begin
	$readmemh( ROM_FILENAME, rom);
end

/**************************************
 *
 *
 *
 */

always @(posedge strobe) begin
	case (command)
	`BUSCMD_LOAD_PC: begin
		// $display("ROM - LOAD_PC %5h", address);
		pc_ptr <= address;
		i_cmd <= `BUSCMD_PC_READ;
	end
	`BUSCMD_PC_READ: begin
		// $display("ROM PC_READ %5h -> %h", pc_ptr, rom[pc_ptr]);
		nibble_out <= rom[pc_ptr];
		pc_ptr <= pc_ptr + 1;
		i_cmd <= command;
	end
	endcase
end

endmodule

`endif
