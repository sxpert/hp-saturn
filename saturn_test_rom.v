/*
    (c) Raphaël Jacquot 2019

    This file is part of hp_saturn.

    hp_saturn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    hp_saturn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

 */

`ifndef _SATURN_TEST_ROM
`define _SATURN_TEST_ROM

`include "def-buscmd.v"

/******************************************************************************
 *
 * test rom
 *
 ****************************************************************************/

module saturn_test_rom (
	i_phase,

	i_reset,
	i_bus_data_in,
  o_bus_data_out,
	i_bus_strobe,
	i_bus_cmd_data
);

input  wire [1:0] i_phase;

input  wire [0:0] i_reset;
input  wire [3:0] i_bus_data_in;
output reg  [3:0] o_bus_data_out;
input  wire [0:0] i_bus_strobe;
input  wire [0:0] i_bus_cmd_data; 

reg  [31:0] cycles;

`ifdef SIM
`define ROMBITS 20
`else 
`define ROMBITS 12
`endif

reg  [3:0]  rom [0:2**`ROMBITS-1];

reg  [19:0] local_pc;
reg  [19:0] local_dp;

reg  [3:0]  last_bus_cmd;
reg  [2:0]  addr_c;
wire [0:0]  s_load_pc;
wire [0:0]  s_load_dp;
wire [0:0]  s_pc_read;
wire [0:0]  s_dp_read;
wire [0:0]  s_dp_write;
assign s_load_pc  = (last_bus_cmd == `BUSCMD_LOAD_PC);
assign s_load_dp  = (last_bus_cmd == `BUSCMD_LOAD_DP);
assign s_pc_read  = (last_bus_cmd == `BUSCMD_PC_READ); 
assign s_dp_read  = (last_bus_cmd == `BUSCMD_DP_READ); 
assign s_dp_write = (last_bus_cmd == `BUSCMD_DP_WRITE); 

initial begin
  $readmemh("rom-gx-r.hex", rom, 0, 2**`ROMBITS-1);
//   $readmemh("testrom-2.hex", rom, 0, 2**`ROMBITS-1);
	// $monitor("rst %b | strb %b | c/d %b | bus_i %h | bus_o %h | last %h | slpc %b | addr_c %0d | lpc %5h | ldp %5h",
	//         i_reset, i_bus_strobe, i_bus_cmd_data, i_bus_data_in, o_bus_data_out, 
	// 				last_bus_cmd, s_load_pc, addr_c, local_pc, local_dp);
end

always @(posedge i_bus_strobe) begin
  
	if (i_reset) begin
	  cycles       <= 0;
	  last_bus_cmd <= `BUSCMD_NOP;
	  addr_c       <= 0;
	  local_pc     <= 0;
		local_dp     <= 0;
	end

	if (!i_reset) 
	  cycles <= cycles + 1;


  if (!i_bus_cmd_data) begin

	  $write("ROM      %0d: [%d] COMMAND ", i_phase, cycles);
		case (i_bus_data_in) 
		  `BUSCMD_PC_READ:   $write("PC_READ");            // 2
			`BUSCMD_DP_WRITE:  $write("DP_WRITE");					 // 5
		  `BUSCMD_LOAD_PC:   $write("LOAD_PC");            // 6
			`BUSCMD_LOAD_DP:   $write("LOAD_DP");						 // 7
			`BUSCMD_CONFIGURE: $write("CONFIGURE (ignore)"); // 8
			`BUSCMD_RESET:     $write("RESET (ignore)");     // 15
		endcase
	  $write(" (%h)\n", i_bus_data_in);

		last_bus_cmd <= i_bus_data_in;
	end

	// if (i_bus_cmd_data) begin
	//   $display("BUS DATA %h", i_bus_data_in);
	// end

	if (i_bus_cmd_data && s_load_pc) begin
		$display("ROM      %0d: [%d] ADDR_IN(%0d) %h => PC [%5h]", i_phase, cycles, addr_c, i_bus_data_in, local_pc);
	  local_pc[addr_c*4+:4] <= i_bus_data_in;
		if (addr_c == 4) $display("ROM       : [%d] auto PC_READ [%5h]", cycles, {i_bus_data_in, local_pc[15:0]});
		last_bus_cmd <= (addr_c == 4)?`BUSCMD_PC_READ:last_bus_cmd;
		addr_c <= (addr_c == 4)?0:addr_c + 1;
	end

	if (i_bus_cmd_data && s_load_dp) begin
		$display("ROM      %0d: [%d] ADDR_IN(%0d) %h => DP [%5h]", i_phase, cycles, addr_c, i_bus_data_in, local_dp);
	  local_dp[addr_c*4+:4] <= i_bus_data_in;
		if (addr_c == 4) $display("ROM       : [%d] auto DP_READ [%5h]", cycles, {i_bus_data_in, local_dp[15:0]});
		last_bus_cmd <= (addr_c == 4)?`BUSCMD_DP_READ:last_bus_cmd;
		addr_c <= (addr_c == 4)?0:addr_c + 1;
	end

  if (i_bus_cmd_data && s_pc_read) begin
	  o_bus_data_out <= rom[local_pc];
		$display("ROM      %0d: [%d] %h <= PC_READ  [%5h]", i_phase, cycles, rom[local_pc], local_pc);
		local_pc <= local_pc + 1;
	end

  if (i_bus_cmd_data && s_dp_read) begin
	  o_bus_data_out <= rom[local_dp];
		$display("ROM      %0d: [%d] %h <= DP_READ  [%5h]", i_phase, cycles, rom[local_dp], local_dp);
		local_dp <= local_dp + 1;
	end

  if (i_bus_cmd_data && s_dp_write) begin
		$display("ROM      %0d: [%d] %h => DP_WRITE [%5h] (ignored)", i_phase, cycles, i_bus_data_in, local_dp);
	end

end

endmodule

`endif
