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

`ifndef _SATURN_DECODER_BLOCK_VARS
`define _SATURN_DECODER_BLOCK_VARS

/*
 *
 * Block vars registers
 *
 */

reg    block_0x;
wire   do_block_0x;
assign do_block_0x = do_on_other_nibbles && block_0x;

reg    block_0Efx;
wire   do_block_0Efx;
assign do_block_0Efx = do_on_other_nibbles && block_0Efx;

reg    block_1x;
wire   do_block_1x;
assign do_block_1x = do_on_other_nibbles && block_1x;

reg    block_save_to_R_W;
wire   do_block_save_to_R_W;
assign do_block_save_to_R_W = do_on_other_nibbles && block_save_to_R_W;                  

reg    block_rest_from_R_W;
wire   do_block_rest_from_R_W;
assign do_block_rest_from_R_W = do_on_other_nibbles && block_rest_from_R_W;       

reg    block_exch_with_R_W;
wire   do_block_exch_with_R_W;
assign do_block_exch_with_R_W = do_on_other_nibbles && block_exch_with_R_W;    

wire   do_block_Rn_A_C;
assign do_block_Rn_A_C = do_on_other_nibbles && 
                         ( block_save_to_R_W   ||
                           block_rest_from_R_W ||
                           block_exch_with_R_W );

reg   block_13x;
wire  do_block_13x;
assign do_block_13x = do_on_other_nibbles && block_13x; 

reg   block_14x_15xx;
wire  do_block_14x_15xx;
assign do_block_14x_15xx = do_on_other_nibbles && block_14x_15xx;        

reg   block_15xx;
wire  do_block_15xx;
assign do_block_15xx = do_on_other_nibbles && block_15xx;        

reg    block_pointer_arith_const;
wire   do_block_pointer_arith_const;
assign do_block_pointer_arith_const = do_on_other_nibbles && block_pointer_arith_const; 

reg   block_2x;
wire  do_block_2x;
assign do_block_2x = do_on_other_nibbles && block_2x;

reg    block_3x;
wire   do_block_3x;
assign do_block_3x = do_on_other_nibbles && block_3x;

reg    block_8x;
wire   do_block_8x;
assign do_block_8x = do_on_other_nibbles && block_8x;

reg   block_80x;
wire  do_block_80x;
assign do_block_80x = do_on_other_nibbles && block_80x;

reg   block_80Cx;
wire  do_block_80Cx;
assign do_block_80Cx = do_on_other_nibbles && block_80Cx;

reg   block_81x;
wire  do_block_81x;
assign do_block_81x = do_on_other_nibbles && block_81x;

reg   block_81Ax;
wire  do_block_81Ax;
assign do_block_81Ax = do_on_other_nibbles && block_81Ax;

reg   block_81Af0x;
wire  do_block_81Af0x;
assign do_block_81Af0x = do_on_other_nibbles && block_81Af0x;

reg   block_81Af1x;
wire  do_block_81Af1x;
assign do_block_81Af1x = do_on_other_nibbles && block_81Af1x;

reg   block_81Af2x;
wire  do_block_81Af2x;
assign do_block_81Af2x = do_on_other_nibbles && block_81Af2x;

reg   block_81Afx;
wire  do_block_81Afx;
assign do_block_81Afx = do_on_other_nibbles && block_81Afx;

reg   block_82x;
wire  do_block_82x;
assign do_block_82x = do_on_other_nibbles && block_82x;

reg  block_84x_85x;
wire do_block_84x_85x;
assign do_block_84x_85x = do_on_other_nibbles && block_84x_85x;

reg    block_8Ax;
wire   do_block_8Ax;
assign do_block_8Ax = do_on_other_nibbles && block_8Ax;

reg    block_jump_test;
reg    block_jump_test2;
wire   do_block_jump_test;
wire   do_block_jump_test2;
assign do_block_jump_test = do_on_other_nibbles && block_jump_test;
assign do_block_jump_test2 = do_on_other_nibbles && block_jump_test2;

reg    block_9x;
wire   do_block_9x;
assign do_block_9x = do_on_other_nibbles && block_9x;

reg   block_9ax;
wire  do_block_9ax;
assign do_block_9ax = do_on_other_nibbles && block_9ax;

reg   block_9bx;
wire  do_block_9bx;
assign do_block_9bx = do_on_other_nibbles && block_9bx;

reg    block_Ax;
wire   do_block_Ax;
assign do_block_Ax = do_on_other_nibbles && block_Ax;

reg   block_Aax;
wire  do_block_Aax;
assign do_block_Aax = do_on_other_nibbles && block_Aax;

reg   block_Abx;
wire  do_block_Abx;
assign do_block_Abx = do_on_other_nibbles && block_Abx;

reg    block_Bx;
wire   do_block_Bx;
assign do_block_Bx = do_on_other_nibbles && block_Bx;

reg   block_Bax;
wire  do_block_Bax;
assign do_block_Bax = do_on_other_nibbles && block_Bax;

reg   block_Bbx;
wire  do_block_Bbx;
assign do_block_Bbx = do_on_other_nibbles && block_Bbx;

reg   block_Cx;
wire  do_block_Cx;
assign do_block_Cx = do_on_other_nibbles && block_Cx;

reg   block_Dx;
wire  do_block_Dx;
assign do_block_Dx = do_on_other_nibbles && block_Dx;

reg   block_Fx;
wire  do_block_Fx;
assign do_block_Fx = do_on_other_nibbles && block_Fx;

reg   go_fields_table;

/*
 * subroutines
 */

reg  block_load_reg_imm;
wire do_load_reg_imm;
assign do_load_reg_imm = do_on_other_nibbles && block_load_reg_imm;

reg  block_jmp;
wire do_block_jmp;
assign do_block_jmp = do_on_other_nibbles && block_jmp;


wire in_fields_table;
assign in_fields_table = go_fields_table && !fields_table_done;

`endif