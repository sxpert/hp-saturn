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

output wire [4:0]  o_program_data;
output wire [4:0]  o_program_address;
input  wire [4:0]  i_program_address;

output reg  [0:0]  o_no_read;
input  wire [3:0]  i_nibble;

output wire [0:0]  o_error;
assign o_error = control_unit_error || dec_error;

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

wire [0:0] reg_dest_c      = (dec_alu_reg_dest == `ALU_REG_C);
wire [0:0] reg_dest_hst    = (dec_alu_reg_dest == `ALU_REG_HST);
wire [0:0] reg_dest_st     = (dec_alu_reg_dest == `ALU_REG_ST);
wire [0:0] reg_dest_p      = (dec_alu_reg_dest == `ALU_REG_P);

wire [0:0] reg_src_1_p     = (dec_alu_reg_src_1 == `ALU_REG_P);
wire [0:0] reg_src_1_imm   = (dec_alu_reg_src_1 == `ALU_REG_IMM);

wire [0:0] aluop_copy      = inst_alu && (dec_alu_opcode == `ALU_OP_COPY);
wire [0:0] aluop_clr_mask  = inst_alu && (dec_alu_opcode == `ALU_OP_CLR_MASK);

wire [0:0] inst_alu_p_eq_n     = aluop_copy && reg_dest_p && reg_src_1_imm;
wire [0:0] inst_alu_c_eq_p_n   = aluop_copy && reg_dest_c && reg_src_1_p;
wire [0:0] inst_alu_clrhst_n   = aluop_clr_mask && reg_dest_hst && reg_src_1_imm;
wire [0:0] inst_alu_st_eq_01_n = aluop_copy && reg_dest_st && reg_src_1_imm;

wire [0:0] inst_alu_other      = !(inst_alu_p_eq_n || 
                                   inst_alu_st_eq_01_n ||
                                   inst_alu_c_eq_p_n);


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
    .i_jump_instr       (inst_jump),
    .i_jump_length      (dec_jump_length),
    .i_block_0x         (dec_block_0x),
    .i_push_pc          (dec_push_pc),
    .i_rtn_instr        (inst_rtn),
    
    .o_current_pc       (reg_PC),
    .o_reload_pc        (reload_PC),

    .i_dbg_rstk_ptr     (i_dbg_rstk_ptr),
    .o_dbg_rstk_val     (o_dbg_rstk_val),
    .o_reg_rstk_ptr     (o_reg_rstk_ptr)
);

/**************************************************************************************************
 *
 * other processor registers
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
reg  [3:0]  reg_HST;
reg  [15:0] reg_ST;
reg  [3:0]  reg_P;
wire [19:0] reg_PC;


wire [0:0]  reload_PC;

always @(i_dbg_register, i_dbg_reg_ptr) begin
    case (i_dbg_register)
    `ALU_REG_A:  o_dbg_reg_nibble <= reg_A[i_dbg_reg_ptr];
    `ALU_REG_B:  o_dbg_reg_nibble <= reg_B[i_dbg_reg_ptr];
    `ALU_REG_C:  o_dbg_reg_nibble <= reg_C[i_dbg_reg_ptr];
    `ALU_REG_D:  o_dbg_reg_nibble <= reg_D[i_dbg_reg_ptr];
    `ALU_REG_D0: o_dbg_reg_nibble <= reg_D0[i_dbg_reg_ptr];
    `ALU_REG_D1: o_dbg_reg_nibble <= reg_D1[i_dbg_reg_ptr];
    default: o_dbg_reg_nibble <= 4'h0;
    endcase
end

/**************************************************************************************************
 *
 * the control unit
 *
 *************************************************************************************************/

reg  [0:0] control_unit_error;
reg  [0:0] just_reset;
reg  [3:0] init_counter;
reg  [0:0] control_unit_ready;
reg  [4:0] bus_program[0:31];
reg  [4:0] bus_prog_addr;
reg  [2:0] addr_nibble_ptr;
reg  [0:0] load_pc_loop;
reg  [0:0] send_reg_C_A;
reg  [0:0] send_pc_read;

wire [3:0] reg_PC_nibble = reg_PC[addr_nibble_ptr*4+:4];

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
    load_pc_loop       = 1'b0;
    send_reg_C_A       = 1'b0;
    send_pc_read       = 1'b0;

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
        reg_A[init_counter] <= 4'h0;
        reg_B[init_counter] <= 4'h0;
        reg_C[init_counter] <= 4'h0;
        reg_D[init_counter] <= 4'h0;
        reg_D0[init_counter] <= 4'h0;
        reg_D1[init_counter] <= 4'h0;
        init_counter <= init_counter + 4'b1;
    end

    /************************
     *
     * we're just starting, load the PC into the controller and modules
     * this could also be used when loading the PC on jumps, need to identify conditions
     *
     */

    if (i_clk_en && (just_reset || reload_PC) && i_phases[3])  begin
        /* this happend right after reset */
        if (just_reset) begin
`ifdef SIM
            $display("CTRL     %0d: [%d] we were just reset, loading PC", i_phase, i_cycle_ctr);
`endif
            just_reset <= 1'b0;
        end else begin
`ifdef SIM
            $display("CTRL     %0d: [%d] reloading PC", i_phase, i_cycle_ctr);
`endif
        end
        /* this loads the PC to the modules */
        bus_program[bus_prog_addr] <= {1'b1, `BUSCMD_LOAD_PC };
`ifdef SIM
        $display("CTRL     %0d: [%d] pushing LOAD_PC command to pos %d", i_phase, i_cycle_ctr, bus_prog_addr);
`endif
        addr_nibble_ptr   <= 3'b0;
        bus_prog_addr     <= bus_prog_addr + 5'd1;
        load_pc_loop      <= 1'b1;
    end 

    /* loop to fill the initial PC value in the program */
    if (i_clk_en && load_pc_loop) begin
        /* 
         * this should load the actual PC values...
         */
        bus_program[bus_prog_addr] <= {1'b0, reg_PC_nibble };
        addr_nibble_ptr   <= addr_nibble_ptr + 3'd1;
        bus_prog_addr     <= bus_prog_addr + 5'd1;
`ifdef SIM
        if (addr_nibble_ptr == 3'd0)
            $display("CTRL     %0d: [%d] new PC value %5h", i_phase, i_cycle_ctr, reg_PC);
        $write("CTRL     %0d: [%d] pushing ADDR : prog[%2d] <= PC[%0d] (%h)", i_phase, i_cycle_ctr, 
               bus_prog_addr, addr_nibble_ptr, {1'b0, reg_PC_nibble });
`endif
        if (addr_nibble_ptr == 3'd4) begin
            load_pc_loop       <= 1'b0;
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
                `INSTR_TYPE_JUMP: begin end
                `INSTR_TYPE_RTN: 
                    begin
                        case (dec_alu_opcode)
                            `ALU_OP_SET_CRY: reg_CARRY <= o_alu_imm_value[0];
                            default: 
                                begin
                                    $display("CTRL     %0d: [%d] alu_opcode for RTN %0d", i_phase, i_cycle_ctr, dec_alu_opcode);
                                    control_unit_error <= 1'b1;
                                end
                        endcase
                    end
                `INSTR_TYPE_LOAD: 
                    begin
                        case (dec_alu_reg_dest)
                            `ALU_REG_C:  reg_C[dec_alu_ptr_begin] <= dec_alu_imm_value;
                            `ALU_REG_D0: reg_D0[dec_alu_ptr_begin] <= dec_alu_imm_value;
                            default: 
                                begin 
                                    $display("CTRL     %0d: [%d] unsupported register for load %0d", i_phase, i_cycle_ctr, dec_alu_reg_dest);
                                    control_unit_error <= 1'b1;
                                end
                        endcase
                    end
                `INSTR_TYPE_CONFIG:
                    begin
                        $display("CTRL     %0d: [%d] exec : CONFIG", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {1'b1, `BUSCMD_CONFIGURE };
                        bus_prog_addr   <= bus_prog_addr + 5'd1;
                        addr_nibble_ptr <= 3'b0;
                        send_reg_C_A    <= 1'b1;
                    end
                `INSTR_TYPE_RESET:
                    begin
                        $display("CTRL     %0d: [%d] exec : RESET", i_phase, i_cycle_ctr);
                        bus_program[bus_prog_addr] <= {1'b1, `BUSCMD_RESET };
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

        /*
         * send C(A)
         * used for CONFIG and UNCNFG
         */
        if (send_reg_C_A) begin
            bus_program[bus_prog_addr] <= { 1'b0, reg_C[{1'b0, addr_nibble_ptr}]};
            addr_nibble_ptr <= addr_nibble_ptr + 3'd1;
            bus_prog_addr <= bus_prog_addr + 5'd1;
            if (addr_nibble_ptr == 3'd4) begin
                addr_nibble_ptr <= 3'd0;
                send_pc_read <= 1'b1;
                send_reg_C_A <= 1'b0;
            end
        end
        
        /*
         * sends the PC_READ command to restore devices after some other bus command
         */
        if (send_pc_read) begin
            $display("CTRL     %0d: [%d] exec : RESET - send PC_READ", i_phase, i_cycle_ctr);
            bus_program[bus_prog_addr] <= {1'b1, `BUSCMD_PC_READ };
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
        load_pc_loop       <= 1'b0;
        send_reg_C_A       <= 1'b0;
        send_pc_read       <= 1'b0; 

        /* registers */
        reg_alu_mode       <= 1'b0;
        reg_CARRY          <= 1'b0;
        reg_HST            <= 4'b0;
        reg_ST             <= 16'b0;
        reg_P              <= 4'b0; 
    end

end

endmodule



