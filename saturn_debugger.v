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

`include "saturn_def_debugger.v"
`include "saturn_def_alu.v"

module saturn_debugger (
    i_clk,
    i_clk_en,
    i_reset,
    i_phases,
    i_phase,
    i_cycle_ctr,

    o_debug_cycle,

    /* interface from the control unit */
    i_current_pc,
    i_reg_alu_mode,
    i_reg_hst,
    i_reg_st,
    i_reg_p,

    o_dbg_register,
    o_dbg_reg_ptr,
    i_dbg_reg_nibble,
    o_dbg_rstk_ptr,
    i_dbg_rstk_val,
    i_reg_rstk_ptr,

    i_alu_reg_dest,
    i_alu_reg_src_1,
    i_alu_reg_src_2,
    i_alu_imm_value,
    i_alu_opcode,

    i_instr_type,
    i_instr_decoded,

    /* output to leds */
    o_char_to_send,
    o_char_valid,
    i_serial_busy
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_clk_en;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;

output reg  [0:0]  o_debug_cycle;

/* inteface from the control unit */
input  wire [19:0] i_current_pc;
input  wire [0:0]  i_reg_alu_mode;
input  wire [3:0]  i_reg_hst;
input  wire [15:0] i_reg_st;
input  wire [3:0]  i_reg_p;

output reg  [4:0]  o_dbg_register;
output wire [3:0]  o_dbg_reg_ptr;
assign o_dbg_reg_ptr = registers_reg_ptr[3:0];
input  wire [3:0]  i_dbg_reg_nibble;
output reg  [2:0]  o_dbg_rstk_ptr;
input  wire [19:0] i_dbg_rstk_val;
input  wire [2:0]  i_reg_rstk_ptr;

input  wire [4:0]  i_alu_reg_dest;
input  wire [4:0]  i_alu_reg_src_1;
input  wire [4:0]  i_alu_reg_src_2;
input  wire [3:0]  i_alu_imm_value;
input  wire [4:0]  i_alu_opcode;

input  wire [3:0]  i_instr_type;
input  wire [0:0]  i_instr_decoded;

output reg  [7:0]  o_char_to_send;
output reg  [0:0]  o_char_valid;
input  wire [0:0]  i_serial_busy;

/**************************************************************************************************
 *
 * debugger process registers
 *
 *************************************************************************************************/

reg  [8:0] counter;
reg  [0:0] write_out;

wire [0:0] debug_done;

assign debug_done = registers_done;

reg  [7:0]  hex[0:15];

reg  [8:0]  registers_ctr;
reg  [7:0]  registers_str[0:511];
reg  [6:0]  registers_state;
reg  [5:0]  registers_reg_ptr;
reg  [0:0]  registers_done;

reg  [0:0]  carry;

initial begin
    o_debug_cycle     = 1'b0;
    counter           = 9'd0;
    write_out         = 1'b0;
    hex[0]            = "0";
    hex[1]            = "1";
    hex[2]            = "2";
    hex[3]            = "3";
    hex[4]            = "4";
    hex[5]            = "5";
    hex[6]            = "6";
    hex[7]            = "7";
    hex[8]            = "8";
    hex[9]            = "9";
    hex[10]           = "A";
    hex[11]           = "B";
    hex[12]           = "C";
    hex[13]           = "D";
    hex[14]           = "E";
    hex[15]           = "F";
    registers_ctr     = 9'd0;
    registers_state   = `DBG_REG_PC_STR;
    registers_reg_ptr = 6'b0;
    o_dbg_register    = `ALU_REG_NONE;
    registers_done    = 1'b0;
    o_char_valid      = 1'b0;
    carry = 1'b1;
end

/**************************************************************************************************
 *
 * debugger process 
 *
 *************************************************************************************************/

always @(posedge i_clk) begin

    if (i_clk_en && i_phases[3] && i_instr_decoded) begin
        $display("DEBUGGER %0d: [%d] start debugger cycle", i_phase, i_cycle_ctr);
        o_debug_cycle   <= 1'b1;
        counter         <= 9'd0;
        registers_ctr   <= 9'd0;
        registers_state <= `DBG_REG_PC_STR;
    end

    /*
     * generates the registers string
     *          0123456789012
     * PC: xxxxx             Carry: x h: @E@ rp: x   RSTK7: xxxxx         
     * P:  x  HST: bbbb      ST:  bbbbbbbbbbbbbbbb   RSTK6: xxxxx
     * A:  xxxxxxxxxxxxxxxx  R0:  xxxxxxxxxxxxxxxx   RSTK5: xxxxx
     * B:  xxxxxxxxxxxxxxxx  R1:  xxxxxxxxxxxxxxxx   RSTK4: xxxxx
     * C:  xxxxxxxxxxxxxxxx  R2:  xxxxxxxxxxxxxxxx   RSTK3: xxxxx
     * D:  xxxxxxxxxxxxxxxx  R3:  xxxxxxxxxxxxxxxx   RSTK2: xxxxx
     * D0: xxxxx  D1: xxxxx  R4:  xxxxxxxxxxxxxxxx   RSTK1: xxxxx
     *                                               RSTK0: xxxxx
       0123456789012345678901234567890123456789012345
     *
     */
    if (o_debug_cycle && !debug_done) begin
        // $display("DEBUGGER %0d: [%d] debugger %0d", i_phase, i_cycle_ctr, registers_ctr);
        case (registers_state)
            `DBG_REG_PC_STR: 
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "P";
                        6'd1: registers_str[registers_ctr] <= "C";
                        6'd2: registers_str[registers_ctr] <= ":";
                        6'd3: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd3) begin
                        registers_reg_ptr <= 6'd4;
                        registers_state <= `DBG_REG_PC_VALUE;
                    end
                end
            `DBG_REG_PC_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[i_current_pc[(registers_reg_ptr)*4+:4]];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_PC_SPACES;
                    end
                end
            `DBG_REG_PC_SPACES:
                begin
                    registers_str[registers_ctr] <= " ";
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd12) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_CARRY;
                    end
                end
            `DBG_REG_CARRY:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "C";
                        6'd1: registers_str[registers_ctr] <= "a";
                        6'd2: registers_str[registers_ctr] <= "r";
                        6'd3: registers_str[registers_ctr] <= "r";
                        6'd4: registers_str[registers_ctr] <= "y";
                        6'd5: registers_str[registers_ctr] <= ":";
                        6'd6: registers_str[registers_ctr] <= " ";
                        6'd7: registers_str[registers_ctr] <= hex[{3'b000,carry}];
                        6'd8: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd8) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_CALC_MODE;
                    end
                end
            `DBG_REG_CALC_MODE:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "h";
                        6'd1: registers_str[registers_ctr] <= ":";
                        6'd2: registers_str[registers_ctr] <= " ";
                        6'd3: registers_str[registers_ctr] <= i_reg_alu_mode?"D":"H";
                        6'd4: registers_str[registers_ctr] <= "E";
                        6'd5: registers_str[registers_ctr] <= i_reg_alu_mode?"C":"X";
                        6'd6: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd6) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_RSTK_PTR;
                    end
                end
            `DBG_REG_RSTK_PTR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "r";
                        6'd1: registers_str[registers_ctr] <= "p";
                        6'd2: registers_str[registers_ctr] <= ":";
                        6'd3: registers_str[registers_ctr] <= " ";
                        6'd4: registers_str[registers_ctr] <= hex[{1'b0, i_reg_rstk_ptr}];
                        6'd5: registers_str[registers_ctr] <= " ";
                        6'd6: registers_str[registers_ctr] <= " ";
                        6'd7: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd7) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_RSTK7_STR;
                    end
                end
            `DBG_REG_RSTK7_STR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "R";
                        6'd1: registers_str[registers_ctr] <= "S";
                        6'd2: registers_str[registers_ctr] <= "T";
                        6'd3: registers_str[registers_ctr] <= "K";
                        6'd4: registers_str[registers_ctr] <= "7";
                        6'd5: registers_str[registers_ctr] <= ":";
                        6'd6: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd6) begin
                        registers_reg_ptr <= 6'd4;
                        o_dbg_rstk_ptr  <= 3'd7;
                        registers_state <= `DBG_REG_RSTK7_VALUE;
                    end
                end
            `DBG_REG_RSTK7_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[i_dbg_rstk_val[(registers_reg_ptr)*4+:4]];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_NL_0;
                    end
                end
            `DBG_REG_NL_0: 
                begin
                    registers_str[registers_ctr] <= "\n";
                    registers_state <= `DBG_REG_P;
                end
            `DBG_REG_P:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "P";
                        6'd1: registers_str[registers_ctr] <= ":";
                        6'd2: registers_str[registers_ctr] <= " ";
                        6'd3: registers_str[registers_ctr] <= " ";
                        6'd4: registers_str[registers_ctr] <= hex[i_reg_p];
                        6'd5: registers_str[registers_ctr] <= " ";
                        6'd6: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd6) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_HST;
                    end
                end
            `DBG_REG_HST:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "H";
                        6'd1: registers_str[registers_ctr] <= "S";
                        6'd2: registers_str[registers_ctr] <= "T";
                        6'd3: registers_str[registers_ctr] <= ":";
                        6'd4: registers_str[registers_ctr] <= " ";
                        6'd5: registers_str[registers_ctr] <= hex[{3'b000, i_reg_hst[3]}];
                        6'd6: registers_str[registers_ctr] <= hex[{3'b000, i_reg_hst[2]}];
                        6'd7: registers_str[registers_ctr] <= hex[{3'b000, i_reg_hst[1]}];
                        6'd8: registers_str[registers_ctr] <= hex[{3'b000, i_reg_hst[0]}];
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd8) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_HST_SPACES;
                    end
                end
            `DBG_REG_HST_SPACES:
                begin
                    registers_str[registers_ctr] <= " ";
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd5) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_ST_STR;
                    end
                end
            `DBG_REG_ST_STR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "S";
                        6'd1: registers_str[registers_ctr] <= "T";
                        6'd2: registers_str[registers_ctr] <= ":";
                        6'd3: registers_str[registers_ctr] <= " ";
                        6'd4: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd4) begin
                        registers_reg_ptr <= 6'd15;
                        registers_state <= `DBG_REG_ST_VALUE;
                    end
                end
            `DBG_REG_ST_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[{3'b000, i_reg_st[registers_reg_ptr]}];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_ST_SPACES;
                    end
                end
            `DBG_REG_ST_SPACES:
                begin
                    registers_str[registers_ctr] <= " ";
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd2) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_RSTK6_STR;
                    end
                end
            `DBG_REG_RSTK6_STR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "R";
                        6'd1: registers_str[registers_ctr] <= "S";
                        6'd2: registers_str[registers_ctr] <= "T";
                        6'd3: registers_str[registers_ctr] <= "K";
                        6'd4: registers_str[registers_ctr] <= "6";
                        6'd5: registers_str[registers_ctr] <= ":";
                        6'd6: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd6) begin
                        registers_reg_ptr <= 6'd4;
                        o_dbg_rstk_ptr  <= 3'd6;
                        registers_state <= `DBG_REG_RSTK6_VALUE;
                    end
                end
            `DBG_REG_RSTK6_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[i_dbg_rstk_val[(registers_reg_ptr)*4+:4]];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_NL_1;
                    end
                end
            `DBG_REG_NL_1: 
                begin
                    registers_str[registers_ctr] <= "\n";
                    registers_state <= `DBG_REG_C_STR;
                end
            `DBG_REG_C_STR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "C";
                        6'd1: registers_str[registers_ctr] <= ":";
                        6'd2: registers_str[registers_ctr] <= " ";
                        6'd3: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd3) begin
                        registers_reg_ptr <= 6'd15;
                        o_dbg_register  <= `ALU_REG_C;
                        registers_state <= `DBG_REG_C_VALUE;
                    end
                end
            `DBG_REG_C_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[i_dbg_reg_nibble];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        o_dbg_register  <= `ALU_REG_NONE;
                        registers_state <= `DBG_REG_NL_6;
                    end
                end
            `DBG_REG_NL_6: 
                begin
                    registers_str[registers_ctr] <= "\n";
                    registers_state <= `DBG_REG_SPACES_7;
                end
            `DBG_REG_SPACES_7:
                begin
                    registers_str[registers_ctr] <= " ";
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd45) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_RSTK0_STR;
                    end
                end
            `DBG_REG_RSTK0_STR:
                begin 
                    case (registers_reg_ptr)
                        6'd0: registers_str[registers_ctr] <= "R";
                        6'd1: registers_str[registers_ctr] <= "S";
                        6'd2: registers_str[registers_ctr] <= "T";
                        6'd3: registers_str[registers_ctr] <= "K";
                        6'd4: registers_str[registers_ctr] <= "0";
                        6'd5: registers_str[registers_ctr] <= ":";
                        6'd6: registers_str[registers_ctr] <= " ";
                    endcase
                    registers_reg_ptr <= registers_reg_ptr + 6'd1;
                    if (registers_reg_ptr == 6'd6) begin
                        registers_reg_ptr <= 6'd4;
                        o_dbg_rstk_ptr  <= 3'd0;
                        registers_state <= `DBG_REG_RSTK0_VALUE;
                    end
                end
            `DBG_REG_RSTK0_VALUE:
                begin
                    registers_str[registers_ctr] <= hex[i_dbg_rstk_val[(registers_reg_ptr)*4+:4]];
                    registers_reg_ptr <= registers_reg_ptr - 6'd1;
                    if (registers_reg_ptr == 6'd0) begin
                        registers_reg_ptr <= 6'd0;
                        registers_state <= `DBG_REG_NL_7;
                    end
                end
            `DBG_REG_NL_7: 
                begin
                    registers_str[registers_ctr] <= "\n";
                    registers_state <= `DBG_REG_END;
                end
            `DBG_REG_END: begin end
            default: begin $display("ERROR, unknown register state %0d", registers_state); end
        endcase
        if (registers_state == `DBG_REG_END)
            registers_done <= 1'b1;
        else
            registers_ctr <= registers_ctr + 9'd1;
    end

    if (i_clk_en && o_debug_cycle && debug_done && !write_out) begin
        $display("DEBUGGER %0d: [%d] end debugger cycle", i_phase, i_cycle_ctr);
        write_out <= 1'b1;
    end

    /* writes the chars to the serial port */
    if (i_clk_en && write_out && !o_char_valid && !i_serial_busy) begin
        o_char_to_send <= registers_str[counter];
        o_char_valid   <= 1'b1;
        counter <= counter + 9'd1;
`ifdef SIM
        $write("%c", registers_str[counter]);
`endif
        if (counter == registers_ctr) begin
`ifdef SIM
            $write("$ %0d chars written", counter + 9'd1);
            $display("");
`endif
            write_out      <= 1'b0;
            registers_done <= 1'b0;
            o_debug_cycle  <= 1'b0;
        end
    end
    /* clear the char clock enable */
    if (write_out && o_char_valid) begin
        o_char_valid <= 1'b0;
    end

    if (i_reset) begin
        o_debug_cycle     <= 1'b0;
        counter           <= 9'b0;
        registers_ctr     <= 9'd0;
        registers_state   <= `DBG_REG_PC_STR;
        registers_reg_ptr <= 6'b0;
        o_dbg_register    <= `ALU_REG_NONE;
        registers_done    <= 1'b0;
        write_out         <= 1'b0;
        o_char_valid      <= 1'b0;
    end

end

endmodule

