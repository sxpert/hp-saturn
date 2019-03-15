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
    i_read,
    i_nibble,

    o_error,

    /* alu is busy doing something */
    o_alu_busy,
    o_exec_unit_busy,

    /* debugger interface */

    o_current_pc,
    o_reg_alu_mode,
    o_reg_carry,
    o_reg_p,
    o_reg_hst,
    o_reg_st,
    /* register access */
    i_dbg_register,
    i_dbg_reg_ptr,
    o_dbg_reg_nibble,
    i_dbg_rstk_ptr,
    o_dbg_rstk_val,
    o_reg_rstk_ptr,

    o_alu_reg_dest,
    o_alu_reg_src_1,
    o_alu_reg_src_2,
    o_alu_imm_value,
    o_alu_opcode,

    o_instr_type,
    o_instr_decoded,
    o_instr_execute
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;

output wire [5:0]  o_program_data;
output wire [4:0]  o_program_address;
input  wire [4:0]  i_program_address;

output reg  [0:0]  o_no_read;
input  wire [0:0]  i_read;
input  wire [3:0]  i_nibble;

output wire [0:0]  o_error;
assign o_error = control_unit_error || dec_error;

output wire [0:0]  o_alu_busy;
output wire [0:0]  o_exec_unit_busy;
assign o_alu_busy       = inst_alu_other || alu_start;
assign o_exec_unit_busy = i_bus_busy ||
                          alu_busy   ||
                          jump_busy  ||
                          rtn_busy   ||
                          mem_read_busy  || 
                          mem_write_busy ||
                          reset_busy ||
                          config_busy;

/* debugger interface */

output wire [19:0] o_current_pc;
output wire [0:0]  o_reg_alu_mode;
output wire [0:0]  o_reg_carry;
output wire [3:0]  o_reg_p;
output wire [3:0]  o_reg_hst;
output wire [15:0] o_reg_st;
/* register access */
input  wire [4:0]  i_dbg_register;
input  wire [3:0]  i_dbg_reg_ptr;
output reg  [3:0]  o_dbg_reg_nibble;
input  wire [2:0]  i_dbg_rstk_ptr;
output wire [19:0] o_dbg_rstk_val;
output wire [2:0]  o_reg_rstk_ptr;
 
output wire [4:0]  o_alu_reg_dest;
output wire [4:0]  o_alu_reg_src_1;
output wire [4:0]  o_alu_reg_src_2;
output wire [3:0]  o_alu_imm_value;
output wire [4:0]  o_alu_opcode;

output wire [3:0]  o_instr_type;
output wire [0:0]  o_instr_decoded;
output wire [0:0]  o_instr_execute;

assign o_current_pc    = reg_PC;
assign o_reg_alu_mode  = reg_alu_mode;
assign o_reg_carry     = reg_CARRY;
assign o_reg_p         = reg_P;
assign o_reg_hst       = reg_HST;
assign o_reg_st        = reg_ST;

assign o_alu_reg_dest  = dec_alu_reg_dest;
assign o_alu_reg_src_1 = dec_alu_reg_src_1;
assign o_alu_reg_src_2 = dec_alu_reg_src_2;
assign o_alu_imm_value = dec_alu_imm_value;
assign o_alu_opcode    = dec_alu_opcode;

assign o_instr_type    = dec_instr_type;
assign o_instr_decoded = dec_instr_decoded;
assign o_instr_execute = dec_instr_execute;

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
    .i_alu_busy         (o_alu_busy),
    .i_exec_unit_busy   (o_exec_unit_busy),

    .i_nibble           (i_nibble),
    .i_reg_p            (reg_P),
    .i_current_pc       (reg_PC),

    .o_alu_reg_dest     (dec_alu_reg_dest),
    .o_alu_reg_src_1    (dec_alu_reg_src_1),
    .o_alu_reg_src_2    (dec_alu_reg_src_2),
    .o_alu_ptr_begin    (dec_alu_ptr_begin),
    .o_alu_ptr_end      (dec_alu_ptr_end),
    .o_alu_imm_value    (dec_alu_imm_value),
    .o_alu_opcode       (dec_alu_opcode),

    .o_jump_length      (dec_jump_length),
    .o_block_0x         (dec_block_0x),

    .o_mem_pointer      (dec_mem_pointer),

    .o_instr_type       (dec_instr_type),
    .o_push_pc          (dec_push_pc),
    .o_instr_decoded    (dec_instr_decoded),
    .o_instr_execute    (dec_instr_execute),

    .o_decoder_error    (dec_error)
);

wire [4:0] dec_alu_reg_dest;
wire [4:0] dec_alu_reg_src_1;
wire [4:0] dec_alu_reg_src_2;
wire [3:0] dec_alu_ptr_begin;
wire [3:0] dec_alu_ptr_end;
wire [3:0] dec_alu_imm_value;
wire [4:0] dec_alu_opcode;

wire [2:0] dec_jump_length;
/* this is necessary to identify possible RTN in time */
wire [0:0] dec_block_0x;

wire [0:0] dec_mem_pointer;

wire [3:0] dec_instr_type;
wire [0:0] dec_push_pc;
wire [0:0] dec_instr_decoded;
wire [0:0] dec_instr_execute;

wire [0:0] dec_error;

/*
 * wires for decode shortcuts
 */

wire [0:0] inst_alu        = (dec_instr_type == `INSTR_TYPE_ALU);
wire [0:0] inst_jump       = (dec_instr_type == `INSTR_TYPE_JUMP);
wire [0:0] inst_rtn        = (dec_instr_type == `INSTR_TYPE_RTN);
wire [0:0] inst_mem_read  = (dec_instr_type == `INSTR_TYPE_MEM_READ);
wire [0:0] inst_mem_write = (dec_instr_type == `INSTR_TYPE_MEM_WRITE);
wire [0:0] inst_reset      = (dec_instr_type == `INSTR_TYPE_RESET);
wire [0:0] inst_config     = (dec_instr_type == `INSTR_TYPE_CONFIG);

wire [0:0] reg_dest_c      = (dec_alu_reg_dest == `ALU_REG_C);
wire [0:0] reg_dest_hst    = (dec_alu_reg_dest == `ALU_REG_HST);
wire [0:0] reg_dest_st     = (dec_alu_reg_dest == `ALU_REG_ST);
wire [0:0] reg_dest_p      = (dec_alu_reg_dest == `ALU_REG_P);

wire [0:0] reg_src_1_a     = (dec_alu_reg_src_1 == `ALU_REG_A);
wire [0:0] reg_src_1_c     = (dec_alu_reg_src_1 == `ALU_REG_C);
wire [0:0] reg_src_1_p     = (dec_alu_reg_src_1 == `ALU_REG_P);
wire [0:0] reg_src_1_imm   = (dec_alu_reg_src_1 == `ALU_REG_IMM);

wire [0:0] aluop_zero      = inst_alu && (dec_alu_opcode == `ALU_OP_ZERO);
wire [0:0] aluop_copy      = inst_alu && (dec_alu_opcode == `ALU_OP_COPY);
wire [0:0] aluop_clr_mask  = inst_alu && (dec_alu_opcode == `ALU_OP_CLR_MASK);

wire [0:0] inst_alu_p_eq_n     = aluop_copy && reg_dest_p && reg_src_1_imm;
wire [0:0] inst_alu_c_eq_p_n   = aluop_copy && reg_dest_c && reg_src_1_p;
wire [0:0] inst_alu_clrhst_n   = aluop_clr_mask && reg_dest_hst && reg_src_1_imm;
wire [0:0] inst_alu_st_eq_01_n = aluop_copy && reg_dest_st && reg_src_1_imm;

wire [0:0] inst_alu_other      =  inst_alu &&
                                  !(inst_alu_p_eq_n || 
                                   inst_alu_c_eq_p_n ||
                                   inst_alu_clrhst_n ||
                                   inst_alu_st_eq_01_n
                                  );

wire [0:0] alu_busy       = inst_alu_other                   || alu_start;
wire [0:0] jump_busy      = (inst_jump && dec_instr_decoded) || send_reg_PC || just_reset;
wire [0:0] rtn_busy       = (inst_rtn && dec_instr_decoded)  || send_reg_PC;
wire [0:0] mem_read_busy  = inst_mem_read                    || exec_mem_read;
wire [0:0] mem_write_busy = inst_mem_write                   || exec_mem_write;
wire [0:0] reset_busy     = inst_reset;
wire [0:0] config_busy    = inst_config;

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
    .i_exec_unit_busy   (o_exec_unit_busy),

    .i_nibble           (i_nibble),
    .i_jump_instr       (inst_jump),
    .i_jump_length      (dec_jump_length),
    .i_block_0x         (dec_block_0x),
    .i_push_pc          (dec_push_pc),
    
    .o_current_pc       (reg_PC),

    .i_dbg_rstk_ptr     (i_dbg_rstk_ptr),
    .o_dbg_rstk_val     (o_dbg_rstk_val),
    .o_reg_rstk_ptr     (o_reg_rstk_ptr)
);

/**************************************************************************************************
 *
 * Processor registers
 *
 *************************************************************************************************/

reg  [0:0]  reg_alu_mode;

reg  [0:0]  reg_CARRY;
reg  [3:0]  reg_A[0:15];
reg  [3:0]  reg_B[0:15];
reg  [3:0]  reg_C[0:15];
reg  [3:0]  reg_D[0:15];
reg  [3:0]  reg_D0[0:4];
reg  [3:0]  reg_D1[0:4];
reg  [3:0]  reg_R0[0:15];
reg  [3:0]  reg_R1[0:15];
reg  [3:0]  reg_R2[0:15];
reg  [3:0]  reg_R3[0:15];
reg  [3:0]  reg_R4[0:15];
reg  [3:0]  reg_HST;
reg  [15:0] reg_ST;
reg  [3:0]  reg_P;
wire [19:0] reg_PC;

/**************************************************************************************************
 *
 * ALU module
 * 
 *************************************************************************************************/

/*
 * ALU control variable
 */

reg  [0:0]  alu_start;

reg  [4:0]  alu_opcode;
reg  [4:0]  alu_reg_dest;
reg  [4:0]  alu_reg_src_1;
reg  [4:0]  alu_reg_src_2;

reg  [3:0]  alu_ptr_begin;
reg  [3:0]  alu_ptr_end;

reg  [0:0]  alu_prep_run;
reg  [3:0]  alu_prep_pos;
reg  [3:0]  alu_prep_src_1_val;
reg  [3:0]  alu_prep_src_2_val;
reg  [0:0]  alu_prep_carry;
reg  [0:0]  alu_prep_done;

reg  [0:0]  alu_calc_run;
reg  [3:0]  alu_calc_pos;
reg  [3:0]  alu_calc_res_1_val;
reg  [3:0]  alu_calc_res_2_val;
reg  [0:0]  alu_calc_carry;
reg  [0:0]  alu_calc_done;

reg  [0:0]  alu_save_run;
reg  [3:0]  alu_save_pos;
reg  [0:0]  alu_save_done;

reg  [3:0]  alu_imm_value;

wire [0:0]  alu_run  = alu_calc_run  || alu_save_run;
wire [0:0]  alu_done = alu_calc_done || alu_save_done; 

/*
 * should we reload the PC after it has been changed
 */

always @(i_dbg_register, i_dbg_reg_ptr) begin
    case (i_dbg_register)
    `ALU_REG_A:  o_dbg_reg_nibble = reg_A[i_dbg_reg_ptr];
    `ALU_REG_B:  o_dbg_reg_nibble = reg_B[i_dbg_reg_ptr];
    `ALU_REG_C:  o_dbg_reg_nibble = reg_C[i_dbg_reg_ptr];
    `ALU_REG_D:  o_dbg_reg_nibble = reg_D[i_dbg_reg_ptr];
    `ALU_REG_D0: o_dbg_reg_nibble = reg_D0[i_dbg_reg_ptr[2:0]];
    `ALU_REG_D1: o_dbg_reg_nibble = reg_D1[i_dbg_reg_ptr[2:0]];
    `ALU_REG_R0: o_dbg_reg_nibble = reg_R0[i_dbg_reg_ptr];
    `ALU_REG_R1: o_dbg_reg_nibble = reg_R1[i_dbg_reg_ptr];
    `ALU_REG_R2: o_dbg_reg_nibble = reg_R2[i_dbg_reg_ptr];
    `ALU_REG_R3: o_dbg_reg_nibble = reg_R3[i_dbg_reg_ptr];
    `ALU_REG_R4: o_dbg_reg_nibble = reg_R4[i_dbg_reg_ptr];
    default:     o_dbg_reg_nibble = 4'h0;
    endcase
end

/**************************************************************************************************
 *
 * the control unit
 *
 *************************************************************************************************/

reg  [0:0]  control_unit_error;
reg  [0:0]  just_reset;
reg  [3:0]  init_counter;
reg  [0:0]  control_unit_ready;
reg  [5:0]  bus_program[0:31];
reg  [4:0]  bus_prog_addr;
reg  [2:0]  addr_nibble_ptr;

reg  [0:0]  send_reg_PC;
reg  [0:0]  send_reg_C_A;
reg  [0:0]  send_reg_D0_D1;
reg  [0:0]  send_reg_D0_D1_done;
reg  [0:0]  send_dp_write;
reg  [0:0]  exec_mem_read;
reg  [0:0]  exec_mem_write;
reg  [3:0]  mem_access_ptr;

reg  [0:0]  send_pc_read;


//wire [3:0] reg_PC_nibble = reg_PC[addr_nibble_ptr*4+:4];

assign o_program_data = bus_program[i_program_address];
assign o_program_address = bus_prog_addr;

initial begin
    /* control variables */
    o_no_read          = 1'b0;
    control_unit_error = 1'b0;
    just_reset         = 1'b1;
    init_counter       = 4'b0;
    control_unit_ready = 1'b0;
    bus_prog_addr      = 5'd0;
    addr_nibble_ptr    = 3'd0;

    send_reg_PC         = 1'b0;
    send_reg_C_A        = 1'b0;
    send_pc_read        = 1'b0;
    send_reg_D0_D1      = 1'b0;
    send_reg_D0_D1_done = 1'b0;
    send_dp_write       = 1'b0;
    exec_mem_read       = 1'b0;
    exec_mem_write      = 1'b0;
    mem_access_ptr      = 4'h0;

    /* alu control signals */
    alu_start          = 1'b0;

    /* registers */
    reg_alu_mode       = 1'b0;
    reg_CARRY          = 1'b0;
    reg_HST            = 4'b0;
    reg_ST             = 16'b0;
    reg_P              = 4'b0; 
end

always @(posedge i_clk) begin

    if (just_reset || (init_counter != 0)) begin
        $display("CTRL     %0d: [%d] initializing registers %0d", i_phase, i_cycle_ctr, init_counter);
        reg_A[init_counter]  <= 4'h0;
        reg_B[init_counter]  <= 4'h0;
        reg_C[init_counter]  <= 4'h0;
        reg_D[init_counter]  <= 4'h0;
        reg_D0[init_counter[2:0]] <= 4'h0;
        reg_D1[init_counter[2:0]] <= 4'h0;
        reg_R0[init_counter] <= 4'h0;
        reg_R1[init_counter] <= 4'h0;
        reg_R2[init_counter] <= 4'h0;
        reg_R3[init_counter] <= 4'h0;
        reg_R4[init_counter] <= 4'h0;
        init_counter <= init_counter + 4'b1;

        /************************
        *
        * all registers are initialized.
        * load the PC into the controller and modules
        *
        */
        if (init_counter == 4'hF) begin
            just_reset <= 1'b0;
            $display("CTRL     %0d: [%d] pushing LOAD_PC command to pos %d", i_phase, i_cycle_ctr, bus_prog_addr);
            bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_LOAD_PC };
            bus_prog_addr     <= bus_prog_addr + 5'd1;
            addr_nibble_ptr   <= 3'b0;
            send_reg_PC     <= 1'b1;
            control_unit_ready <= 1'b1;
        end
    end

    /************************
     *
     * main execution loop
     *
     */

    if (i_clk_en && control_unit_ready) begin

        if (i_phases[3] && !i_bus_busy && dec_instr_execute) begin
            case (dec_instr_type) 
                `INSTR_TYPE_NOP: begin 
                        $display("CTRL     %0d: [%d] NOP instruction", i_phase, i_cycle_ctr);
                    end
                `INSTR_TYPE_ALU: begin
                        $display("CTRL     %0d: [%d] ALU instruction", i_phase, i_cycle_ctr);

                        /*
                         * treat special cases
                         */
                        /* 2n      P=         n */
                        if (inst_alu_p_eq_n) begin
                            $display("CTRL     %0d: [%d] exec : P= %h", i_phase, i_cycle_ctr, dec_alu_imm_value);
                            reg_P <= dec_alu_imm_value;
                        end

                        /* 80Cn    C=P        n */
                        if (inst_alu_c_eq_p_n) begin
                            reg_C[dec_alu_ptr_begin] <= reg_P;
                        end

                        if (inst_alu_clrhst_n) begin
`ifdef SIM
                            $write("CTRL     %0d: [%d] exec : ", i_phase, i_cycle_ctr);
                            case (dec_alu_imm_value)
                                4'h1: $display("XM=0");
                                4'h2: $display("SB=0");
                                4'h4: $display("SR=0");
                                4'h8: $display("MP=0");
                                4'hF: $display("CLRHST");
                                default: $display("CLRHST %h", dec_alu_imm_value);
                            endcase
`endif
                            reg_HST <= reg_HST & ~dec_alu_imm_value;
                        end

                        /* 8[45]n  ST=[01]    n */
                        if (inst_alu_st_eq_01_n) begin
                            $display("CTRL     %0d: [%d] exec : ST=%b %h", i_phase, i_cycle_ctr, dec_alu_imm_value[0], dec_alu_ptr_begin);
                            reg_ST[dec_alu_ptr_begin] <= dec_alu_imm_value[0];
                        end

                        /*
                         * the general case
                         */
                        if (inst_alu_other) begin
                            $display("CTRL     %0d: [%d] exec : generic ALU operation", i_phase, i_cycle_ctr);
                            alu_start     <= 1'b1;
                            alu_opcode    <= dec_alu_opcode;
                            alu_reg_dest  <= dec_alu_reg_dest;
                            alu_reg_src_1 <= dec_alu_reg_src_1;
                            alu_reg_src_2 <= dec_alu_reg_src_2;
                            alu_ptr_begin <= dec_alu_ptr_begin;
                            alu_ptr_end   <= dec_alu_ptr_end;
                            alu_prep_pos  <= dec_alu_ptr_begin;
                            alu_calc_pos  <= dec_alu_ptr_begin;
                            alu_save_pos  <= dec_alu_ptr_begin;
                            alu_imm_value <= dec_alu_imm_value;

                            alu_prep_done <= 1'b0;
                            alu_calc_done <= 1'b0;
                            alu_save_done <= 1'b0;

                            if (aluop_zero) 
                                begin
                                    alu_calc_res_1_val <= 4'h0;
                                    alu_save_run  <= 1'b1;
                                end
                            else alu_prep_run <= 1'b1;
                        end
                    end
                `INSTR_TYPE_SET_MODE :
                    begin
`ifdef SIM
                        $write("CTRL     %0d: [%d] exec : ", i_phase, i_cycle_ctr);
                        case (dec_alu_imm_value)
                            4'h0: $display("SETHEX");
                            4'h1: $display("SETDEC");
                            default: begin end /* does not exist */
                        endcase
`endif
                        reg_alu_mode <= dec_alu_imm_value[0];
                    end
                `INSTR_TYPE_JUMP,
                `INSTR_TYPE_RTN: 
                    begin
                        if (inst_jump) begin 
                            $display("CTRL     %0d: [%d] JUMP", i_phase, i_cycle_ctr); 
                        end
                        if (inst_rtn) begin 
                            $display("CTRL     %0d: [%d] RTN", i_phase, i_cycle_ctr); 
                            case (dec_alu_opcode)
                                `ALU_OP_SET_CRY: reg_CARRY <= o_alu_imm_value[0];
                                default: 
                                    begin
                                        $display("CTRL     %0d: [%d] alu_opcode for RTN %0d", i_phase, i_cycle_ctr, dec_alu_opcode);
                                        control_unit_error <= 1'b1;
                                    end
                            endcase
                        end

                        if (dec_instr_decoded) begin
                            $display("CTRL     %0d: [%d] exec : JUMP/RTN reload pc to %5h", i_phase, i_cycle_ctr, reg_PC); 
                            bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_LOAD_PC };
                            bus_prog_addr   <= bus_prog_addr + 5'd1;
                            addr_nibble_ptr <= 3'b0;
                            send_reg_PC     <= 1'b1;
                        end

                    end
                `INSTR_TYPE_LOAD: 
                    begin
                        case (dec_alu_reg_dest)
                            `ALU_REG_C:  reg_C[dec_alu_ptr_begin] <= dec_alu_imm_value;
                            `ALU_REG_D0: reg_D0[dec_alu_ptr_begin[2:0]] <= dec_alu_imm_value;
                            `ALU_REG_D1: reg_D1[dec_alu_ptr_begin[2:0]] <= dec_alu_imm_value;
                            default: 
                                begin 
                                    $display("CTRL     %0d: [%d] unsupported register for load %0d", i_phase, i_cycle_ctr, dec_alu_reg_dest);
                                    control_unit_error <= 1'b1;
                                end
                        endcase
                    end
                `INSTR_TYPE_MEM_READ:
                    begin
                        $display("CTRL     %0d: [%d] MEM READ", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_LOAD_DP };
                        bus_prog_addr   <= bus_prog_addr + 5'd1;
                        addr_nibble_ptr <= 3'b0;
                        send_reg_D0_D1  <= 1'b1;
                        exec_mem_read   <= 1'b1;
                    end
                `INSTR_TYPE_MEM_WRITE:
                    begin
                        $display("CTRL     %0d: [%d] MEM WRITE", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_LOAD_DP };
                        bus_prog_addr   <= bus_prog_addr + 5'd1;
                        addr_nibble_ptr <= 3'b0;
                        send_reg_D0_D1  <= 1'b1;
                        exec_mem_write  <= 1'b1;
                    end
                `INSTR_TYPE_CONFIG:
                    begin
                        $display("CTRL     %0d: [%d] exec : CONFIG", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_CONFIGURE };
                        bus_prog_addr   <= bus_prog_addr + 5'd1;
                        addr_nibble_ptr <= 3'b0;
                        send_reg_C_A    <= 1'b1;
                    end
                `INSTR_TYPE_RESET:
                    begin
                        $display("CTRL     %0d: [%d] exec : RESET", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_RESET };
                        bus_prog_addr <= bus_prog_addr + 5'd1;
                        send_pc_read  <= 1'b1;
                    end
                default: 
                    begin 
                        $display("CTRL     %0d: [%d] unsupported instruction", i_phase, i_cycle_ctr);
                        control_unit_error <= 1'b1;

                    end
            endcase
        end

    /**********************************************************************************************
     *
     * sending bus programs 
     *
     *********************************************************************************************/

        /******************************************************************************************
         *
         * sending the value of the PC
         *
         *****************************************************************************************/

        if (send_reg_PC) begin
            $display("CTRL     %0d: [%d] exec: send_reg_PC[%0d] %h", i_phase, i_cycle_ctr, addr_nibble_ptr, reg_PC[addr_nibble_ptr*4+:4] );
            bus_program[bus_prog_addr] <= { 2'b00, reg_PC[addr_nibble_ptr*4+:4] };
            addr_nibble_ptr <= addr_nibble_ptr + 3'd1;
            bus_prog_addr   <= bus_prog_addr + 5'd1;
            if (addr_nibble_ptr == 3'd4) begin
                addr_nibble_ptr <= 3'd0;
                send_reg_PC     <= 1'b0;
            end
        end

        /******************************************************************************************
         *
         * CONFIG and UNCNFG stuff
         *
         *****************************************************************************************/
        
        /*
         * send C(A)
         * used for CONFIG and UNCNFG
         */
        if (send_reg_C_A) begin
            bus_program[bus_prog_addr] <= { 2'b00, reg_C[{1'b0, addr_nibble_ptr}]};
            addr_nibble_ptr <= addr_nibble_ptr + 3'd1;
            bus_prog_addr <= bus_prog_addr + 5'd1;
            if (addr_nibble_ptr == 3'd4) begin
                addr_nibble_ptr <= 3'd0;
                send_pc_read <= 1'b1;
                send_reg_C_A <= 1'b0;
            end
        end
        
    /******************************************************************************************
     *
     * ALU pipeline
     *
     *****************************************************************************************/

        /**********
         *
         * ALU prepare source values
         * 
         */

        if (alu_start && alu_prep_run && !alu_prep_done) begin
            $display("ALU_PREP %0d: [%d] b %h | p %h | e %h", i_phase, i_cycle_ctr, alu_ptr_begin, alu_prep_pos, alu_ptr_end);

            case (dec_alu_reg_src_1)
                `ALU_REG_A: alu_prep_src_1_val <= reg_A[alu_prep_pos];
                `ALU_REG_B: alu_prep_src_1_val <= reg_B[alu_prep_pos];
                `ALU_REG_C: alu_prep_src_1_val <= reg_C[alu_prep_pos];
                `ALU_REG_D: alu_prep_src_1_val <= reg_D[alu_prep_pos];
                default: $display("ALU_PREP %0d: [%d] unhandled src1 register %0d", i_phase, i_cycle_ctr, dec_alu_reg_src_1);
            endcase

            case (dec_alu_reg_src_2)
                `ALU_REG_A: alu_prep_src_2_val <= reg_A[alu_prep_pos];
                `ALU_REG_B: alu_prep_src_2_val <= reg_B[alu_prep_pos];
                `ALU_REG_C: alu_prep_src_2_val <= reg_C[alu_prep_pos];
                `ALU_REG_D: alu_prep_src_2_val <= reg_D[alu_prep_pos];
                `ALU_REG_NONE: begin end
                default: $display("ALU_PREP %0d: [%d] unhandled src2 register %0d", i_phase, i_cycle_ctr, dec_alu_reg_src_2);
            endcase

            /* need to prepare the carry here */

            if (alu_prep_pos == alu_ptr_end) begin
                alu_prep_done <= 1'b1;
                alu_prep_run  <= 1'b0;
            end
            alu_prep_pos <= alu_prep_pos + 4'h1;
            /* start the calc thread */
            alu_calc_run <= 1'b1;
        end

        /**********
         *
         * ALU calculations
         * 
         */

        if (alu_start && alu_calc_run && !alu_calc_done) begin
            $display("ALU_CALC %0d: [%d] b %h | p %h | e %h | s1 %h | s2 %h | c %b", 
                     i_phase, i_cycle_ctr, alu_ptr_begin, alu_calc_pos, alu_ptr_end,
                     alu_prep_src_1_val, alu_prep_src_2_val, alu_prep_carry);

            case (alu_opcode)
                `ALU_OP_ZERO: begin end // this doesn't run, handled directly by the save below
                `ALU_OP_COPY: alu_calc_res_1_val <= alu_prep_src_1_val;
                `ALU_OP_EXCH: 
                    begin
                        alu_calc_res_1_val <= alu_prep_src_2_val;
                        alu_calc_res_2_val <= alu_prep_src_1_val;
                    end
                default: $display("ALU_CALC %0d: [%d] unhandled opcode %0d", i_phase, i_cycle_ctr, alu_opcode);
            endcase

            if (alu_calc_pos == alu_ptr_end) begin
                alu_calc_done <= 1'b1;
                alu_calc_run  <= 1'b0;
            end
            alu_calc_pos <= alu_calc_pos + 4'h1;
            /* start the save thread */
            alu_save_run <= 1'b1;
        end

        /**********
         *
         * ALU save results to registers
         * 
         */

        if (alu_start && alu_save_run && !alu_save_done) begin
            $display("ALU_SAVE %0d: [%d] b %h | p %h | e %h | r1 %h | r2 %h | c %b | rs1 %d | rs2 %d | d %d", 
                     i_phase, i_cycle_ctr, 
                     alu_ptr_begin, alu_save_pos, alu_ptr_end,
                     alu_calc_res_1_val, alu_calc_res_2_val, alu_calc_carry,
                     alu_reg_src_1, alu_reg_src_2, alu_reg_dest);
            
            case (alu_reg_dest)
                `ALU_REG_A:  reg_A[alu_save_pos]  <= alu_calc_res_1_val;
                `ALU_REG_B:  reg_B[alu_save_pos]  <= alu_calc_res_1_val;
                `ALU_REG_C:  reg_C[alu_save_pos]  <= alu_calc_res_1_val;
                `ALU_REG_D:  reg_D[alu_save_pos]  <= alu_calc_res_1_val;
                `ALU_REG_D0: reg_D0[alu_save_pos[2:0]] <= alu_calc_res_1_val;
                `ALU_REG_D1: reg_D1[alu_save_pos[2:0]] <= alu_calc_res_1_val;
                default: $display("ALU_SAVE %0d: [%d] dest register %0d not supported", i_phase, i_cycle_ctr, alu_reg_dest);
            endcase
            
            if (alu_opcode == `ALU_OP_EXCH)
                case (alu_reg_src_2)
                    `ALU_REG_A:  reg_A[alu_save_pos]  <= alu_calc_res_2_val;
                    `ALU_REG_B:  reg_B[alu_save_pos]  <= alu_calc_res_2_val;
                    `ALU_REG_C:  reg_C[alu_save_pos]  <= alu_calc_res_2_val;
                    `ALU_REG_D:  reg_D[alu_save_pos]  <= alu_calc_res_2_val;
                    `ALU_REG_D0: reg_D0[alu_save_pos[2:0]] <= alu_calc_res_2_val;
                    `ALU_REG_D1: reg_D1[alu_save_pos[2:0]] <= alu_calc_res_2_val;
                    default: $display("ALU_SAVE %0d: [%d] exch: src_2 register %0d not supported", i_phase, i_cycle_ctr, alu_reg_src_2);
                endcase

            if (alu_save_pos == alu_ptr_end) begin
                alu_save_done <= 1'b1;
                alu_save_run  <= 1'b0;
            end
            alu_save_pos <= alu_save_pos + 4'h1;
        end


        /**********
         *
         * ALU end of operations
         * 
         */

        if (i_phases[2] && alu_start && alu_save_done) begin
            $display("CTRL     %0d: [%d] end of ALU operation", i_phase, i_cycle_ctr);
            alu_start <= 1'b0;
        end

        if (i_phases[3] && !alu_start) begin
            $display("CTRL     %0d: [%d] ALU is not started", i_phase, i_cycle_ctr);
        end

        /******************************************************************************************
         *
         * Memory operations control
         *
         *****************************************************************************************/
        
        /*
         * send D0 or D1
         */
        if (send_reg_D0_D1) begin
            $display("CTRL     %0d: [%d] exec: sending D%b[%0d] %h", i_phase, i_cycle_ctr, 
                     dec_mem_pointer, addr_nibble_ptr, 
                     dec_mem_pointer?reg_D1[addr_nibble_ptr]:reg_D0[addr_nibble_ptr]);
            bus_program[bus_prog_addr] <= { 2'b00, dec_mem_pointer?reg_D1[addr_nibble_ptr]:reg_D0[addr_nibble_ptr]};
            addr_nibble_ptr <= addr_nibble_ptr + 3'd1;
            bus_prog_addr <= bus_prog_addr + 5'd1;
            if (addr_nibble_ptr == 3'd4) begin
                addr_nibble_ptr     <= 3'd0;
                send_reg_D0_D1      <= 1'b0;
                send_reg_D0_D1_done <= 1'b1;
                send_dp_write       <= exec_mem_write;
                mem_access_ptr      <= dec_alu_ptr_begin;
            end
        end
        
        /* 
         * in case of memory write, send DP_WRITE command
         */
        if (send_reg_D0_D1_done && send_dp_write && exec_mem_write) begin
            $display("CTRL     %0d: [%d] exec: sending DP_WRITE", i_phase, i_cycle_ctr);
            bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_DP_WRITE };
            bus_prog_addr <= bus_prog_addr + 5'd1;
            send_dp_write <= 1'b0;
        end

        /*
         * send the data to write
         */
        if (send_reg_D0_D1_done && !send_dp_write && exec_mem_write) begin
            $display("CTRL     %0d: [%d] exec: writing data %c[%h] %h", i_phase, i_cycle_ctr,
                     reg_src_1_c?"C":"A", mem_access_ptr, 
                     reg_src_1_c?reg_C[mem_access_ptr]:reg_A[mem_access_ptr]);
            bus_program[bus_prog_addr] <= {2'b00, reg_src_1_c?reg_C[mem_access_ptr]:reg_A[mem_access_ptr]};
            mem_access_ptr <= mem_access_ptr + 4'h1;
            bus_prog_addr  <= bus_prog_addr + 5'd1;
            if (mem_access_ptr == dec_alu_ptr_end) begin
                send_reg_D0_D1_done <= 1'b0;
                send_pc_read        <= 1'b1;
            end
        end

        /*
         * send the data to write
         */
        if (send_reg_D0_D1_done && exec_mem_read) begin
            $display("CTRL     %0d: [%d] exec: reading data to %c[%h]", i_phase, i_cycle_ctr,
                     reg_dest_c?"C":"A", mem_access_ptr);
            bus_program[bus_prog_addr] <= 6'b100000;
            mem_access_ptr <= mem_access_ptr + 4'h1;
            bus_prog_addr  <= bus_prog_addr + 5'd1;
            if (mem_access_ptr == dec_alu_ptr_end) begin
                send_reg_D0_D1_done <= 1'b0;
                send_pc_read        <= 1'b1;
                mem_access_ptr      <= 4'b0;
            end
        end

        /*
         * wait for something to read
         */
        if (exec_mem_read && i_phases[2] && i_read) begin
            case (dec_alu_reg_dest)
                `ALU_REG_A: reg_A[mem_access_ptr] <= i_nibble;
                `ALU_REG_C: reg_C[mem_access_ptr] <= i_nibble;
                default: $display("CTRL     %0d: [%d] exec read: unsupported register %0d", i_phase, i_cycle_ctr, dec_alu_reg_dest);
            endcase
            mem_access_ptr <= mem_access_ptr + 4'h1;
        end

        /*
         * wait for the program end, cleanup the exec_read and exec_write flags
         */
        if ((i_program_address == bus_prog_addr) && 
            !(send_reg_D0_D1 || send_reg_D0_D1_done || send_dp_write) && 
            (exec_mem_read || exec_mem_write)) begin
            $display("CTRL     %0d: [%d] exec: memory transfer cleanup", i_phase, i_cycle_ctr);
            exec_mem_read  <= 1'b0;
            exec_mem_write <= 1'b0;
        end

        /******************************************************************************************
         *
         * send the PC_READ command (many things end with this)
         *
         *****************************************************************************************/

        /*
         * sends the PC_READ command to restore devices after some other bus command
         */
        if (send_pc_read) begin
            $display("CTRL     %0d: [%d] exec : RESET - send PC_READ", i_phase, i_cycle_ctr);
            bus_program[bus_prog_addr] <= {2'b01, `BUSCMD_PC_READ };
            bus_prog_addr <= bus_prog_addr + 5'd1;
            send_pc_read  <= 1'b0;
        end


    end

    if (i_reset) begin
        /* control variables */
        o_no_read          <= 1'b0;
        control_unit_error <= 1'b0;
        just_reset         <= 1'b1;
        init_counter       <= 4'b0;
        control_unit_ready <= 1'b0;
        bus_prog_addr      <= 5'd0;
        addr_nibble_ptr    <= 3'd0;

        send_reg_PC         <= 1'b0;
        send_reg_C_A        <= 1'b0;
        send_pc_read        <= 1'b0;
        send_reg_D0_D1      <= 1'b0;
        send_reg_D0_D1_done <= 1'b0;
        send_dp_write       <= 1'b0;
        exec_mem_read       <= 1'b0;
        exec_mem_write      <= 1'b0;
        mem_access_ptr      <= 4'h0; 


        /* alu control signals */
        alu_start          <= 1'b0;

        /* registers */
        reg_alu_mode       <= 1'b0;
        reg_CARRY          <= 1'b0;
        reg_HST            <= 4'b0;
        reg_ST             <= 16'b0;
        reg_P              <= 4'b0; 
    end

end

endmodule



