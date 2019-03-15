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

`include "saturn_def_alu.v"

module saturn_inst_decoder (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,
    
    i_bus_busy,
    i_alu_busy,
    i_exec_unit_busy,

    i_nibble,
    i_reg_p,
    i_current_pc,

    o_instr_pc,

    o_alu_reg_dest,
    o_alu_reg_src_1,
    o_alu_reg_src_2,
    o_alu_field,
    o_alu_ptr_begin,
    o_alu_ptr_end,
    o_alu_imm_value,
    o_alu_opcode,

    o_jump_length,
    o_block_0x,

    o_mem_pointer,

    o_instr_type,
    o_push_pc,
    o_instr_decoded,
    o_instr_execute,

    o_decoder_error,
    /* debugger interface */
    o_dbg_inst_addr
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

input  wire [0:0]  i_bus_busy;
input  wire [0:0]  i_alu_busy;
input  wire [0:0]  i_exec_unit_busy;

input  wire [3:0]  i_nibble;
input  wire [3:0]  i_reg_p;
input  wire [19:0] i_current_pc;

output reg  [19:0] o_instr_pc;

output reg  [4:0]  o_alu_reg_dest;
output reg  [4:0]  o_alu_reg_src_1;
output reg  [4:0]  o_alu_reg_src_2;
output reg  [3:0]  o_alu_field;
output reg  [3:0]  o_alu_ptr_begin;
output reg  [3:0]  o_alu_ptr_end;
output reg  [3:0]  o_alu_imm_value;
output reg  [4:0]  o_alu_opcode;

output reg  [2:0]  o_jump_length;
output wire [0:0]  o_block_0x;
assign o_block_0x = block_0x;

output reg  [0:0]  o_mem_pointer;

output reg  [3:0]  o_instr_type;
output reg  [0:0]  o_push_pc;
/* instruction is fully decoded */
output reg  [0:0]  o_instr_decoded;
/* instruction is sufficiently decoded to start execution */
output reg  [0:0]  o_instr_execute;

output reg  [0:0]  o_decoder_error;
/*
 * debugger interface
 */
/* address of the last instruction */
output reg  [19:0] o_dbg_inst_addr;

/**************************************************************************************************
 *
 * sub-modules go here
 *
 *************************************************************************************************/




/**************************************************************************************************
 *
 * the decoder module
 *
 *************************************************************************************************/

/*
 * process state variables
 */

reg [0:0] just_reset;
reg [0:0] decode_started;

/*
 * decoder block variables
 */

reg [0:0] block_0x;
reg [0:0] block_1x;
reg [0:0] block_14x;
reg [0:0] block_2x;
reg [0:0] block_3x;
reg [0:0] block_8x;
reg [0:0] block_80x;
reg [0:0] block_80Cx;
reg [0:0] block_82x;
reg [0:0] block_84x_85x;
reg [0:0] block_Ax;
reg [0:0] block_Aax;
reg [0:0] block_Abx;
reg [0:0] block_Dx;

reg [0:0] block_JUMP;
reg [0:0] block_LOAD;
reg [0:0] block_FIELDS;

/*
 * temporary variables
 */
reg [2:0] jump_counter;
reg [3:0] load_counter;
reg [3:0] load_count;
reg [1:0] fields_table;

/*
 * initialization
 */

initial begin
    o_alu_reg_dest  = `ALU_REG_NONE;
    o_alu_reg_src_1 = `ALU_REG_NONE;
    o_alu_reg_src_2 = `ALU_REG_NONE;
    o_alu_field     = `FT_FIELD_NONE;
    o_alu_ptr_begin = 4'h0;
    o_alu_ptr_end   = 4'h0;
    o_alu_imm_value = 4'b0;
    o_alu_opcode    = `ALU_OP_NOP;

    o_instr_type    = 4'd15;
    o_push_pc       = 1'd0;
    o_instr_decoded = 1'b0;
    o_instr_execute = 1'b0;

    /* debugger interface */
    o_dbg_inst_addr = 20'b0;

    /* internal registers */
    just_reset      = 1'b1;
    decode_started  = 1'b0;

    block_0x        = 1'b0;
    block_1x        = 1'b0;
    block_14x       = 1'b0;
    block_2x        = 1'b0;
    block_3x        = 1'b0;
    block_8x        = 1'b0;
    block_80x       = 1'b0;
    block_80Cx      = 1'b0;
    block_82x       = 1'b0;
    block_84x_85x   = 1'b0;
    block_Ax        = 1'b0;
    block_Aax       = 1'b0;
    block_Abx       = 1'b0;
    block_Dx        = 1'b0;

    block_JUMP      = 1'b0;
    block_LOAD      = 1'b0;
    block_FIELDS    = 1'b0;

    /* local variables */
    jump_counter    = 3'd0;
    load_counter    = 4'd0;
    load_count      = 4'd0;
    fields_table    = `FT_NONE;

    /* last line of defense */
    o_decoder_error = 1'b0;
end

/****************************
 *
 * registers blocks wires
 *
 */

wire [4:0] regs_ABCD = { 3'b000, i_nibble[1:0] };
wire [4:0] regs_BCAC = { 3'b000, i_nibble[0], !(i_nibble[1] | i_nibble[0]) };
wire [4:0] regs_ABAC = { 3'b000, i_nibble[1] & i_nibble[0], !i_nibble[1] & i_nibble[0] };
wire [4:0] regs_BCCD = { 3'b000, i_nibble[1] | i_nibble[0], !i_nibble[1] ^ i_nibble[0] };

/****************************
 *
 * main process
 *
 */

always @(posedge i_clk) begin
  
    /*
     * only do something when nothing is busy doing some other tasks
     * either talking to the bus, or debugging something
     */

    if (i_clk_en && i_bus_busy && i_phases[2] && just_reset) begin
        // $display("DECODER  %0d: [%d] dump registers right after reset", i_phase, i_cycle_ctr);
        just_reset      <= 1'b0;
        o_instr_decoded <= 1'b1;
    end

    if (i_clk_en && !i_bus_busy && !i_exec_unit_busy) begin
 
        if (i_phases[1] && !decode_started) begin
            // $display("DECODER  %0d: [%d] store current PC as instruction start %5h", i_phase, i_cycle_ctr, i_current_pc);
            o_instr_pc   <= i_current_pc;
            /* set the instruction to NOP, to avoid any stray processes */
            o_instr_type <= `INSTR_TYPE_NOP;
        end

        if (i_phases[2] && !decode_started) begin
            $display("DECODER  %0d: [%d] nb= %h - start instruction decoding", i_phase, i_cycle_ctr, i_nibble);

            decode_started <= 1'b1;
            case (i_nibble)
                4'h0: block_0x <= 1'b1;
                4'h1: block_1x <= 1'b1;
                4'h2: block_2x <= 1'b1;
                4'h3: block_3x <= 1'b1;
                4'h6, 4'h7: 
                    begin
                        o_instr_type    <= `INSTR_TYPE_JUMP;
                        o_push_pc       <= i_nibble[0]; 
                        o_jump_length   <= 3'd2;
                        jump_counter    <= 3'd0;
                        o_instr_execute <= 1'b1;
                        block_JUMP      <= 1'b1;
                    end
                4'h8: block_8x <= 1'b1;
                4'hA: 
                    begin
                        block_Ax     <= 1'b1;
                        block_FIELDS <= 1'b1;
                        fields_table <= `FT_A_B;
                    end
                4'hD: block_Dx <= 1'b1;
                default: 
                    begin
                        $display("invalid instruction");
                        o_decoder_error <= 1'b1;
                    end
            endcase
        end

        if (i_phases[2] && decode_started) begin
            $display("DECODER  %0d: [%d] nb= %h - decoding", i_phase, i_cycle_ctr, i_nibble);

            if (block_0x) begin
                case (i_nibble)
                    4'h2, 4'h3:
                        begin
                            $display("DECODER  %0d: [%d] RTN%cC", i_phase, i_cycle_ctr, i_nibble[0]?"C":"S");
                            o_instr_type    <= `INSTR_TYPE_RTN;
                            o_alu_imm_value <= {3'b000, !i_nibble[0]};
                            o_alu_opcode    <= `ALU_OP_SET_CRY;
                            o_instr_decoded <= 1'b1;
                            o_instr_execute <= 1'b1;
                            decode_started  <= 1'b0;
                        end
                    4'h4, 4'h5:
                        begin
                            o_instr_type    <= `INSTR_TYPE_SET_MODE;
                            o_alu_imm_value <= {3'b000, i_nibble[0]};
                            o_instr_decoded <= 1'b1;
                            o_instr_execute <= 1'b1;
                            decode_started  <= 1'b0;
                        end                            
                    default: 
                        begin
                            $display("DECODER  %0d: [%d] block_0x %h", i_phase, i_cycle_ctr, i_nibble);
                            o_decoder_error <= 1'b1;
                        end
                endcase
                block_0x        <= 1'b0;
            end

            if (block_1x) begin
                case (i_nibble)
                    4'h4: block_14x <= 1'b1;
                    4'hB:
                        begin
                            $display("DECODER  %0d: [%d] D)=(5)", i_phase, i_cycle_ctr, i_nibble);
                            o_alu_reg_dest  <= `ALU_REG_D0;
                            o_alu_ptr_begin <= 4'h0;
                            o_alu_ptr_end   <= 4'h4;
                            load_counter    <= 4'h0;
                            load_count      <= 4'h4;
                            o_instr_execute <= 1'b1;
                            block_LOAD      <= 1'b1;
                        end
                    default: 
                        begin
                            $display("DECODER  %0d: [%d] block_1x %h", i_phase, i_cycle_ctr, i_nibble);
                            o_decoder_error <= 1'b1;
                        end
                endcase
                block_1x        <= 1'b0;
            end

            if (block_14x) begin
                $display("DECODER  %0d: [%d] block_14x %h", i_phase, i_cycle_ctr, i_nibble);
                o_mem_pointer   <= i_nibble[0];
                o_instr_type    <= i_nibble[1]?`INSTR_TYPE_MEM_READ:`INSTR_TYPE_MEM_WRITE;
                o_alu_reg_dest  <= i_nibble[2]?`ALU_REG_C:`ALU_REG_A;
                o_alu_reg_src_1 <= i_nibble[2]?`ALU_REG_C:`ALU_REG_A;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                o_alu_field     <= i_nibble[3]?`FT_FIELD_B:`FT_FIELD_A;
                o_alu_ptr_begin <= 4'h0;
                o_alu_ptr_end   <= i_nibble[3]?1:4;
                o_instr_execute <= 1'b1;
                o_instr_decoded <= 1'b1;
                decode_started  <= 1'b0;
                block_14x       <= 1'b0;
            end

            if (block_2x) begin
                o_alu_reg_dest  <= `ALU_REG_P;
                o_alu_reg_src_1 <= `ALU_REG_IMM;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                o_alu_imm_value <= i_nibble;
                o_alu_opcode    <= `ALU_OP_COPY;
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                block_2x        <= 1'b0;
                decode_started  <= 1'b0;
            end

            if (block_3x) begin
                $display("DECODER  %0d: [%d] LC %h", i_phase, i_cycle_ctr, i_nibble);
                o_alu_reg_dest  <= `ALU_REG_C;
                o_alu_ptr_begin <= i_reg_p;
                o_alu_ptr_end   <= (i_reg_p + i_nibble) & 4'hF;
                load_counter    <= 4'h0;
                load_count      <= i_nibble;
                o_instr_execute <= 1'b1;
                block_LOAD      <= 1'b1;
                block_3x        <= 1'b0;
            end

            if (block_8x) begin
                case (i_nibble)
                    4'h0: block_80x <= 1'b1;
                    4'h2: block_82x <= 1'b1;
                    4'h4, 4'h5: 
                        begin
                            o_alu_reg_dest  <= `ALU_REG_ST;
                            o_alu_reg_src_1 <= `ALU_REG_IMM;
                            o_alu_reg_src_2 <= `ALU_REG_NONE;
                            o_alu_imm_value <= { 3'b000, i_nibble[0]};
                            o_alu_opcode    <= `ALU_OP_COPY;
                            o_instr_type    <= `INSTR_TYPE_ALU;
                            block_84x_85x   <= 1'b1;
                        end
                    4'hD, 4'hF: /* GOVLNG or GOSBVL */
                        begin
                            o_instr_type    <= `INSTR_TYPE_JUMP;
                            o_push_pc       <= i_nibble[1]; 
                            o_jump_length   <= 3'd4;
                            jump_counter    <= 3'd0;
                            o_instr_execute <= 1'b1;
                            block_JUMP      <= 1'b1;
                        end
                    default: 
                        begin
                            $display("DECODER  %0d: [%d] block_8x %h", i_phase, i_cycle_ctr, i_nibble);
                            o_decoder_error <= 1'b1;
                        end
                endcase
                block_8x <= 1'b0;
            end

            if (block_80x) begin
                case (i_nibble)
                    4'h5: /* CONFIG */
                        begin
                            o_instr_type    <= `INSTR_TYPE_CONFIG;
                            o_instr_decoded <= 1'b1;
                            o_instr_execute <= 1'b1;
                            decode_started  <= 1'b0;
                        end
                    4'hA: /* RESET */
                        begin
                            o_instr_type    <= `INSTR_TYPE_RESET;
                            o_instr_decoded <= 1'b1;
                            o_instr_execute <= 1'b1;
                            decode_started  <= 1'b0;  
                        end
                    4'hC: block_80Cx <= 1'b1;
                    default: 
                        begin
                            $display("DECODER  %0d: [%d] block_80x %h", i_phase, i_cycle_ctr, i_nibble);
                            o_decoder_error <= 1'b1;
                        end
                endcase
                block_80x <= 1'b0;
            end

            if (block_80Cx) begin
                $display("DECODER  %0d: [%d] block_80Cx C=P %h", i_phase, i_cycle_ctr, i_nibble);
                o_alu_reg_dest  <= `ALU_REG_C;
                o_alu_reg_src_1 <= `ALU_REG_P;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                o_alu_ptr_begin <= i_nibble;
                o_alu_ptr_end   <= i_nibble;
                o_alu_opcode    <= `ALU_OP_COPY;
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                block_80Cx      <= 1'b0;
                decode_started  <= 1'b0;
            end

            if (block_82x) begin
`ifdef SIM
                $write("DECODER  %0d: [%d] block_82x ", i_phase, i_cycle_ctr);
                case (i_nibble)
                    4'h1: $display("XM=0");
                    4'h2: $display("SB=0");
                    4'h4: $display("SR=0");
                    4'h8: $display("MP=0");
                    4'hF: $display("CLRHST");
                    default: $display("CLRHST %h", i_nibble);
                endcase
`endif
                o_alu_reg_dest  <= `ALU_REG_HST;
                o_alu_reg_src_1 <= `ALU_REG_IMM;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                o_alu_imm_value <= i_nibble;
                o_alu_opcode    <= `ALU_OP_CLR_MASK;
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                decode_started  <= 1'b0;
                block_82x       <= 1'b0;
            end

            if (block_84x_85x) begin
                o_alu_ptr_begin <= i_nibble;
                o_alu_ptr_end   <= i_nibble;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                decode_started  <= 1'b0;
                block_84x_85x   <= 1'b0;
            end

            if (block_Ax) begin
                $display("DECODER  %0d: [%d] block_Ax %h", i_phase, i_cycle_ctr, i_nibble);
                /* work here is done by the block_FIELDS */
                block_Aax <= !i_nibble[3];
                block_Abx <=  i_nibble[3];
                block_Ax  <= 1'b0;
            end

            if (block_Aax) begin
                $display("DECODER  %0d: [%d] block_Aax %h (%0d [%h:%h])", 
                         i_phase, i_cycle_ctr, i_nibble, o_alu_field, o_alu_ptr_end, o_alu_ptr_begin);
                o_decoder_error <= 1'b1;
                block_Aax <= 1'b0;
            end

            if (block_Abx) begin
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                case ({i_nibble[3], i_nibble[2]})
                    2'b00: begin o_alu_reg_dest <= regs_ABCD; o_alu_reg_src_1 <= `ALU_REG_NONE; o_alu_opcode <= `ALU_OP_ZERO; end
                default:
                    begin
                        $display("DECODER  %0d: [%d] block_Abx %h (%0d [%h:%h])", 
                                 i_phase, i_cycle_ctr, i_nibble, o_alu_field, o_alu_ptr_end, o_alu_ptr_begin);
                        o_decoder_error <= 1'b1;
                    end
                endcase
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                decode_started  <= 1'b0;
                block_Abx       <= 1'b0;
            end

            if (block_Dx) begin
                $display("DECODER  %0d: [%d] block_Dx %h", i_phase, i_cycle_ctr, i_nibble);
                o_instr_type    <= `INSTR_TYPE_ALU;
                o_alu_field     <= `FT_FIELD_A;
                o_alu_ptr_begin <= 4'h0;
                o_alu_ptr_end   <= 4'h4;
                o_alu_reg_src_2 <= `ALU_REG_NONE;
                case ({i_nibble[3], i_nibble[2]})
                    2'b00: 
                        begin
                            o_alu_opcode    <= `ALU_OP_ZERO;
                            o_alu_reg_dest  <= regs_ABCD;
                            o_alu_reg_src_1 <= `ALU_REG_NONE;
                        end
                    2'b01:
                        begin
                            o_alu_opcode    <= `ALU_OP_COPY;
                            o_alu_reg_dest  <= regs_ABCD;
                            o_alu_reg_src_1 <= regs_BCAC;
                        end
                    2'b10:
                        begin
                            o_alu_opcode    <= `ALU_OP_COPY;
                            o_alu_reg_dest  <= regs_BCAC;
                            o_alu_reg_src_1 <= regs_ABCD;
                        end
                    2'b11:
                        begin
                            o_alu_opcode    <= `ALU_OP_EXCH;
                            o_alu_reg_dest  <= regs_ABAC;
                            o_alu_reg_src_1 <= regs_ABAC;
                            o_alu_reg_src_2 <= regs_BCCD;
                        end
                endcase
                o_instr_decoded <= 1'b1;
                o_instr_execute <= 1'b1;
                decode_started  <= 1'b0;
                block_Dx <= 1'b0;
            end

            /* special cases */

            if (block_JUMP) begin
                jump_counter <= jump_counter + 3'd1;
                if (jump_counter == o_jump_length) begin
                    block_JUMP      <= 1'b0;
                    o_instr_decoded <= 1'b1;
                    decode_started  <= 1'b0;
                end
            end

            if (block_LOAD) begin
                o_instr_type    <= `INSTR_TYPE_LOAD;
                o_alu_imm_value <= i_nibble;
                load_counter    <= load_counter + 4'd1;
                if (load_counter == load_count) begin
                    block_LOAD <= 1'b0;
                    o_instr_decoded <= 1'b1;
                    decode_started  <= 1'b0;
                end
            end

            if (block_FIELDS) begin
                $display("DECODER  %0d: [%d] block_FIELDS %h", i_phase, i_cycle_ctr, i_nibble);
                o_alu_field <= { 1'b0, i_nibble[2:0] };
                case (i_nibble[2:0])
                    3'o0: 
                        begin
                            /* field pointed by P */
                            o_alu_ptr_begin <= i_reg_p;
                            o_alu_ptr_end   <= i_reg_p;
                        end
                    3'o1:
                        begin
                            /* field the width of P, starting at 0 */
                            o_alu_ptr_begin <= 4'h0;
                            o_alu_ptr_end   <= i_reg_p;
                        end
                    3'o2:
                        begin
                            /* field XS */
                            o_alu_ptr_begin <= 4'h2;
                            o_alu_ptr_end   <= 4'h2;
                        end
                    3'o3:
                        begin
                            /* field X */
                            o_alu_ptr_begin <= 4'h0;
                            o_alu_ptr_end   <= 4'h2;
                        end
                    3'o4:
                        begin
                            /* field S */
                            o_alu_ptr_begin <= 4'hF;
                            o_alu_ptr_end   <= 4'hF;
                        end
                    3'o5:
                        begin
                            /* field M */
                            o_alu_ptr_begin <= 4'h3;
                            o_alu_ptr_end   <= 4'hE;
                        end
                    3'o6:
                        begin
                            /* field B */
                            o_alu_ptr_begin <= 4'h0;
                            o_alu_ptr_end   <= 4'h1;
                        end
                    3'o7:
                        begin
                            if ((fields_table == `FT_F) && i_nibble[3]) 
                                begin
                                    /* this is field A */
                                    o_alu_field     <= i_nibble;
                                    o_alu_ptr_begin <= 4'h0;
                                    o_alu_ptr_end   <= 4'h4;
                                end
                            else
                                begin
                                    /* else this is field W */
                                    o_alu_ptr_begin <= 4'h0;
                                    o_alu_ptr_end   <= 4'hF;
                                end
                        end
                endcase
                block_FIELDS <= 1'b0;
            end

        end

        /* need to increment this at the same time the pointer is used */
        if (i_phases[3] && block_LOAD && (o_instr_type == `INSTR_TYPE_LOAD)) begin
            $display("DECODER  %0d: [%d] load ptr_begin <= %0d", i_phase, i_cycle_ctr, (o_alu_ptr_begin + 4'd1) & 4'hF);
            o_alu_ptr_begin <= (o_alu_ptr_begin + 4'd1) & 4'hF;
        end

        /* o_instr_decoded goes away only when the ALU is not busy anymore */
        if (i_phases[3] && o_instr_decoded) begin
            $display("DECODER  %0d: [%d] decoder cleanup 1", i_phase, i_cycle_ctr);
            o_instr_decoded <= 1'b0;
        end

    end

    if (i_clk_en && !i_bus_busy) begin
        /* decoder cleanup only after the instruction is completely decoded and execution has started */
        if (i_phases[3] && o_instr_decoded) begin
            $display("DECODER  %0d: [%d] decoder cleanup 2", i_phase, i_cycle_ctr);
            fields_table    <= `FT_NONE;
            o_alu_field     <= `FT_FIELD_NONE;
            o_instr_execute <= 1'b0;
            o_instr_type    <= `INSTR_TYPE_NONE;
            o_push_pc       <= 1'b0;
        end
    end


    if (i_reset) begin
        /* stuff that needs reset */
        o_alu_reg_dest  <= `ALU_REG_NONE;
        o_alu_reg_src_1 <= `ALU_REG_NONE;
        o_alu_reg_src_2 <= `ALU_REG_NONE;
        o_alu_field     <= `FT_FIELD_NONE;
        o_alu_ptr_begin <= 4'h0;
        o_alu_ptr_end   <= 4'h0;
        o_alu_imm_value <= 4'b0;
        o_alu_opcode    <= `ALU_OP_NOP;

        o_instr_type    <= 4'd15;
        o_push_pc       <= 1'b0;
        o_instr_decoded <= 1'b0;
        o_instr_execute <= 1'b0;

        /* debugger interface */
        o_dbg_inst_addr <= 20'b0;

        /* internal registers */
        just_reset      <= 1'b1;
        decode_started  <= 1'b0;

        block_0x        <= 1'b0;
        block_1x        <= 1'b0;
        block_14x       <= 1'b0;
        block_2x        <= 1'b0;
        block_3x        <= 1'b0;
        block_8x        <= 1'b0;
        block_80x       <= 1'b0;
        block_80Cx      <= 1'b0;
        block_82x       <= 1'b0;
        block_84x_85x   <= 1'b0;
        block_Ax        <= 1'b0;
        block_Aax       <= 1'b0;
        block_Abx       <= 1'b0;
        block_Dx        <= 1'b0;

        block_JUMP      <= 1'b0;
        block_LOAD      <= 1'b0;
        block_FIELDS    <= 1'b0;

        /* local variables */
        jump_counter    <= 3'd0;
        load_counter    <= 4'd0;
        load_count      <= 4'd0;
        fields_table    <= `FT_NONE;

        /* invalid instruction */
        o_decoder_error <= 1'b0;
    end

end


endmodule
