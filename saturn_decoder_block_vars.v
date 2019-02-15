
/*
 *
 *
 *
 *
 */


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

reg   block_pointer_assign_exch;
wire  do_block_pointer_assign_exch;
assign do_block_pointer_assign_exch = do_on_other_nibbles && block_pointer_assign_exch; 

reg   block_mem_transfer;
wire  do_block_mem_transfer;
assign do_block_mem_transfer = do_on_other_nibbles && block_mem_transfer;        

reg   block_pointer_arith_const;
wire  do_block_pointer_arith_const;
assign do_block_pointer_arith_const = do_on_other_nibbles && block_pointer_arith_const; 

reg   block_load_p;
wire  do_block_load_p;
assign do_block_load_p = do_on_other_nibbles && block_load_p;

reg   block_load_c_hex;
wire  do_block_load_c_hex;
assign do_block_load_c_hex = do_on_other_nibbles && block_load_c_hex;

reg   block_jmp2_cry_set;
reg   block_jmp2_cry_clr;

reg   block_8x;
wire  do_block_8x;
assign do_block_8x = do_on_other_nibbles && block_8x;

reg   block_80x;
wire  do_block_80x;
assign do_block_80x = do_on_other_nibbles && block_80x;

reg   block_80Cx;
wire  do_block_80Cx;
assign do_block_80Cx = do_on_other_nibbles && block_80Cx;

reg   block_82x;
wire  do_block_82x;
assign do_block_82x = do_on_other_nibbles && block_82x;

reg   block_Ax;
wire  do_block_Ax;
assign do_block_Ax = do_on_other_nibbles && block_Ax;

reg   block_Aax;
wire  do_block_Aax;
assign do_block_Aax = do_on_other_nibbles && block_Aax;

reg   block_Abx;
wire  do_block_Abx;
assign do_block_Abx = do_on_other_nibbles && block_Abx;

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

reg  block_sr_bit;
wire do_block_sr_bit;
assign do_block_sr_bit = do_on_other_nibbles && block_sr_bit;

wire in_fields_table;
assign in_fields_table = go_fields_table && !fields_table_done;
