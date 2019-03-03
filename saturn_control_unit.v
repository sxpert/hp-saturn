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

`default_nettype none

`include "saturn_def_buscmd.v" 
`include "saturn_def_alu.v"

module saturn_control_unit (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    i_bus_busy,

    o_program_data,
    o_program_address,
    i_program_address,

    o_no_read,
    i_nibble,

    o_error,

    /* debugger interface */

    o_current_pc,

    o_alu_reg_dest,
    o_alu_reg_src_1,
    o_alu_reg_src_2,
    o_alu_imm_value,
    o_alu_opcode,

    o_instr_type,
    o_instr_decoded
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;

output wire [4:0]  o_program_data;
output wire [4:0]  o_program_address;
input  wire [4:0]  i_program_address;

output reg  [0:0]  o_no_read;
input  wire [3:0]  i_nibble;

output wire [0:0]  o_error;
assign o_error = control_unit_error;

/* debugger interface */

output wire [19:0] o_current_pc;

output wire [4:0]  o_alu_reg_dest;
output wire [4:0]  o_alu_reg_src_1;
output wire [4:0]  o_alu_reg_src_2;
output wire [3:0]  o_alu_imm_value;
output wire [4:0]  o_alu_opcode;

output wire [3:0]  o_instr_type;
output wire [0:0]  o_instr_decoded;

assign o_current_pc    = reg_PC;

assign o_alu_reg_dest  = dec_alu_reg_dest;
assign o_alu_reg_src_1 = dec_alu_reg_src_1;
assign o_alu_reg_src_2 = dec_alu_reg_src_2;
assign o_alu_imm_value = dec_alu_imm_value;
assign o_alu_opcode    = dec_alu_opcode;

assign o_instr_type    = dec_instr_type;
assign o_instr_decoded = dec_instr_decoded;

/**************************************************************************************************
 *
 * decoder module
 *
 *************************************************************************************************/

saturn_inst_decoder instruction_decoder(
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
    .i_phases           (i_phases),
    .i_phase            (i_phase),
    .i_cycle_ctr        (i_cycle_ctr),

    .i_bus_busy         (i_bus_busy),

    .i_nibble           (i_nibble),
    .i_reg_p            (reg_P),
    .i_current_pc       (reg_PC),

    .o_alu_reg_dest     (dec_alu_reg_dest),
    .o_alu_reg_src_1    (dec_alu_reg_src_1),
    .o_alu_reg_src_2    (dec_alu_reg_src_2),
    .o_alu_imm_value    (dec_alu_imm_value),
    .o_alu_opcode       (dec_alu_opcode),

    .o_instr_type       (dec_instr_type),
    .o_instr_decoded    (dec_instr_decoded),
    .o_instr_execute    (dec_instr_execute)
);

wire [4:0] dec_alu_reg_dest;
wire [4:0] dec_alu_reg_src_1;
wire [4:0] dec_alu_reg_src_2;
wire [3:0] dec_alu_imm_value;
wire [4:0] dec_alu_opcode;

wire [3:0] dec_instr_type;
wire [0:0] dec_instr_decoded;
wire [0:0] dec_instr_execute;

/*
 * wires for decode shortcuts
 */

wire [0:0] reg_dest_p    = (dec_alu_reg_dest == `ALU_REG_P);
wire [0:0] reg_src_1_imm = (dec_alu_reg_src_1 == `ALU_REG_IMM);
wire [0:0] aluop_copy    = (dec_alu_opcode == `ALU_OP_COPY);

wire [0:0] inst_alu_p_eq_n = aluop_copy && reg_dest_p && reg_src_1_imm;
wire [0:0] inst_alu_other  = !(inst_alu_p_eq_n);

/**************************************************************************************************
 *
 * registers module (contains A, B, C, D, R0, R1, R2, R3, R4)
 *
 *************************************************************************************************/

/**************************************************************************************************
 *
 * PC and RSTK module
 *
 *************************************************************************************************/

saturn_regs_pc_rstk regs_pc_rstk (
    .i_clk              (i_clk),
    .i_clk_en           (i_clk_en),
    .i_reset            (i_reset),
    .i_phases           (i_phases),
    .i_phase            (i_phase),
    .i_cycle_ctr        (i_cycle_ctr),

    .i_bus_busy         (i_bus_busy),

    .i_nibble           (i_nibble),

    .o_current_pc       (reg_PC)
);

/**************************************************************************************************
 *
 * other processor registers
 *
 *************************************************************************************************/

reg  [3:0]  reg_P;
wire [19:0] reg_PC;

/**************************************************************************************************
 *
 * the control unit
 *
 *************************************************************************************************/

reg  [0:0] control_unit_error;
reg  [0:0] just_reset;
reg  [0:0] control_unit_ready;
reg  [4:0] bus_program[0:31];
reg  [4:0] bus_prog_addr;
reg  [2:0] addr_nibble_ptr;

wire [3:0] reg_PC_nibble = reg_PC[addr_nibble_ptr*4+:4];

assign o_program_data = bus_program[i_program_address];
assign o_program_address = bus_prog_addr;

initial begin
    /* control variables */
    o_no_read          = 1'b0;
    control_unit_error = 1'b0;
    just_reset         = 1'b1;
    control_unit_ready = 1'b0;
    bus_prog_addr      = 5'd0;
    addr_nibble_ptr    = 3'd0;
    
    /* registers */
    reg_P              = 4'b0; 
end

always @(posedge i_clk) begin

    /************************
     *
     * we're just starting, load the PC into the controller and modules
     * this could also be used when loading the PC on jumps, need to identify conditions
     *
     */

    if (i_clk_en && just_reset && i_phases[3]) begin
        /* this happend right after reset */
        if (just_reset) begin
`ifdef SIM
            $display("CTRL     %0d: [%d] we are in the control unit", i_phase, i_cycle_ctr);
`endif
            just_reset <= 1'b0;
        end
        /* this loads the PC to the modules */
        bus_program[bus_prog_addr] <= {1'b1, `BUSCMD_LOAD_PC };
`ifdef SIM
        $display("CTRL     %0d: [%d] pushing LOAD_PC command to pos %d", i_phase, i_cycle_ctr, bus_prog_addr);
`endif
        addr_nibble_ptr   <= 3'b0;
        bus_prog_addr     <= bus_prog_addr + 5'd1;
    end 

    /* loop to fill the initial PC value in the program */
    if (i_clk_en && !control_unit_ready && (bus_prog_addr != 5'b0)) begin
        /* 
         * this should load the actual PC values...
         */
        bus_program[bus_prog_addr] <= {1'b0, reg_PC_nibble };
        addr_nibble_ptr   <= addr_nibble_ptr + 3'd1;
        bus_prog_addr     <= bus_prog_addr + 5'd1;
`ifdef SIM
        $write("CTRL     %0d: [%d] pushing ADDR : prog[%0d] <= PC[%0d] (%h)", i_phase, i_cycle_ctr, 
               bus_prog_addr, addr_nibble_ptr, {1'b0, reg_PC[addr_nibble_ptr*4+:4]});
`endif
        if (bus_prog_addr == 5'd5) begin
            control_unit_ready <= 1'b1;
`ifdef SIM
            $write(" done");
`endif
        end
`ifdef SIM
        $write("\n");
`endif
    end

    /************************
     *
     * main execution loop
     *
     */

    if (i_clk_en && control_unit_ready && !i_bus_busy) begin
        
// `ifdef SIM
        // $display("CTRL     %0d: [%d] starting to do things", i_phase, i_cycle_ctr);
// `endif
        if (i_cycle_ctr == 10) begin
            control_unit_error <= 1'b1;
            $display("CTRL     %0d: [%d] enough cycles for now", i_phase, i_cycle_ctr);
        end

        // if (i_phases[2]) begin
        //     $display("CTRL     %0d: [%d] interpreting %h", i_phase, i_cycle_ctr, i_nibble);
        // end

        if (i_phases[3] && dec_instr_execute) begin
            case (dec_instr_type) 
                `INSTR_TYPE_NOP: begin 
                        $display("CTRL     %0d: [%d] NOP instruction", i_phase, i_cycle_ctr);
                    end
                `INSTR_TYPE_ALU: begin
                        $display("CTRL     %0d: [%d] ALU instruction", i_phase, i_cycle_ctr);

                        /*
                         * treat special cases
                         */
                        if (inst_alu_p_eq_n) begin
                            $display("CTRL     %0d: [%d] exec : P= %h", i_phase, i_cycle_ctr, dec_alu_imm_value);
                            reg_P <= dec_alu_imm_value;
                        end

                        /*
                         * the general case
                         */
                    end
                default: begin 
                        $display("CTRL     %0d: [%d] unsupported instruction", i_phase, i_cycle_ctr);
                    end
            endcase
        end
    end

    if (i_reset) begin
        /* control variables */
        o_no_read          <= 1'b0;
        control_unit_error <= 1'b0;
        just_reset         <= 1'b1;
        control_unit_ready <= 1'b0;
        bus_prog_addr      <= 5'd0;
        addr_nibble_ptr    <= 3'd0;
    
        /* registers */
        reg_P              <= 4'b0; 
    end

end

endmodule



