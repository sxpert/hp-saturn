
//--------------------------------------------------------------------------------------------------
//
// bus control
//
//--------------------------------------------------------------------------------------------------

`include "fields.v"
`include "bus_commands.v"

always @(posedge bus_ctrl_clk)
begin
	if (!reset) begin
		if (clk3) begin
			en_dec_clk <= 0;
			if (cycle_ctr_ready)
				cycle_ctr <= cycle_ctr + 1;
			else cycle_ctr_ready <= 1;
			case (next_cycle)
			`BUSCMD_NOP: begin
				bus_command <= `BUSCMD_NOP;
				// $display("BUS NOT READING, STILL CLOCKING");
			end
			`BUSCMD_PC_READ: begin
				bus_command <= `BUSCMD_PC_READ;
				en_bus_clk <= 1;
				PC <= next_PC;
				inc_pc <= 1;
			end
			`BUSCMD_DP_READ: begin
				bus_command <= `BUSCMD_DP_READ;
				en_bus_clk <= 1;
			end
			`BUSCMD_DP_WRITE: begin
				bus_command <= `BUSCMD_DP_WRITE;
				bus_nibble_in <= nb_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_LOAD_PC: begin
				bus_command <= `BUSCMD_LOAD_PC;
				bus_address <= new_PC;
				next_PC <= new_PC;
				PC <= new_PC;
				en_bus_clk <= 1;
			end
			`BUSCMD_LOAD_DP: begin
				bus_command <= `BUSCMD_LOAD_DP;
				bus_address <= add_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_CONFIGURE: begin
				bus_command <= `BUSCMD_CONFIGURE;
				bus_address <= add_out;
				en_bus_clk <= 1;
			end
			`BUSCMD_RESET: begin
				bus_command <= `BUSCMD_RESET;
				en_bus_clk <= 1;
			end
			default: begin
				$display("BUS PHASE 1: %h UNIMPLEMENTED", next_cycle);
			end
			endcase
		end
		else begin
			case (next_cycle)
			`BUSCMD_NOP: begin
				en_dec_clk <= 1;
			end
			`BUSCMD_PC_READ: begin
				nb_in <= bus_nibble_out;
				en_dec_clk <= 1;
				if (inc_pc) begin
					next_PC <= PC + 1;
					inc_pc <= 0;
				end
				// $display("reading nibble %h", bus_nibble_out);
			end
			`BUSCMD_DP_READ: begin
				nb_in <= bus_nibble_out;
				en_dec_clk <= 1;
			end
			`BUSCMD_DP_WRITE: begin
				// $display("BUS PHASE 2: DP_WRITE cnt %h | ctr %h", t_cnt, t_ctr);
				en_dec_clk <= 1;
			end
			`BUSCMD_LOAD_PC: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_PC %5h", cycle_ctr, instr_ctr, new_PC);
				en_dec_clk <= 1;
			end
			`BUSCMD_LOAD_DP: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_LOAD_DP %s %5h", 
				// 		 cycle_ctr, instr_ctr, t_ptr?"D1":"D0", add_out);
				en_dec_clk <= 1;
			end
			`BUSCMD_CONFIGURE: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_CONFIGURE %5h", cycle_ctr, instr_ctr, add_out); 
				en_dec_clk <= 1;
			end
			`BUSCMD_RESET: begin
				// $display("CYCLE %d | INSTR %d -> BUSCMD_RESET", cycle_ctr, instr_ctr); 
				en_dec_clk <= 1;
			end
			default: begin
				$display("BUS PHASE 2: %h UNIMPLEMENTED", next_cycle);
			end
			endcase
			en_bus_clk <= 0;
		end
	end
	else begin
		$display("RESET");
	end
end

always @(posedge ph0) begin
	if (dbg_op_code)
		case (dbg_op_code)
		default: begin
`ifdef SIM
			$display("DEBUGGER - UNKNOWN OPCODE: %4h", dbg_op_code);
`endif
		end
		endcase
`ifdef SIM
	else $display("DEBUGGER - NOTHING TO DO");
`endif
end

always @(posedge ph1) begin
`include "opcodes/z_alu_phase_1.v"
end

always @(posedge ph2) begin
`include "opcodes/z_alu_phase_2.v"
end

always @(posedge ph3) begin
	if (cycle_ctr == 890)
		debug_stop <= 1;
end
