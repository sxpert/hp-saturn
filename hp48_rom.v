
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

/**************************************
 *
 *
 *
 */

always @(posedge clk)
	case (command)
		`BUSCMD_LOAD_PC:
			begin
`ifdef SIM
				$display("rom: LOAD_PC %5h", address);
`endif
				pc_ptr <= address;
			end
		`BUSCMD_PC_READ:
			begin
`ifdef SIM
			$display("rom: inc PC");
`endif
				pc_ptr <= pc_ptr + 1;
			end
		default: begin end
	endcase

/**************************************
 *
 *
 *
 */

always @(negedge clk)
		case (command)
			`BUSCMD_NOP: begin end				// do nothing	
			`BUSCMD_PC_READ:	
				begin
`ifdef SIM
					//$display("rom: PC_READ %5h => %h", address, rom[pc_ptr]);
`endif
					nibble_out <= rom[pc_ptr];
//					pc_ptr <= pc_ptr + 1;
				end
			`BUSCMD_LOAD_PC: begin end			// do nothing here, handled on @(posedge clk)
			`BUSCMD_LOAD_DP:
				begin
`ifdef SIM
					//$display("rom: LOAD_DP %5h", address);
`endif
					data_ptr <= address;
				end
			default:
				begin
`ifdef SIM
					$display("rom: unknown command (%h) | PC %5h | D %5h", command, pc_ptr, data_ptr);
`endif
				end
		endcase
endmodule

`endif
