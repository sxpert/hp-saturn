
/******************************************************************************
*
* set fields from instruction nibble
*
*****************************************************************************/

`ifdef SIM
`define DEBUG_FIELDS_TABLE
`endif

reg fields_table_done;

/* more wires to decode common states.
 * can possibly be made less redundant / faster ?
 */

wire do_fields_table;
assign do_fields_table = decoder_active && go_fields_table && !fields_table_done;

`ifdef SIM
wire table_a;
wire table_b;
`endif
wire table_f;
wire table_value;
`ifdef SIM
assign table_a     = (o_fields_table == `FT_TABLE_a);
assign table_b     = (o_fields_table == `FT_TABLE_b);
`endif
assign table_f     = (o_fields_table == `FT_TABLE_f);
assign table_value = (o_fields_table == `FT_TABLE_value);

wire do_tables_a_f_b;
assign do_tables_a_f_b = do_fields_table && !table_value;

wire table_f_bit_3;
wire [3:0] table_a_f_b_case_value;
assign table_f_bit_3 = table_f && i_nibble[3];
assign table_a_f_b_case_value = {table_f_bit_3, i_nibble[2:0]};

/* value generation for debug
 */

`ifdef SIM
wire table_a_nb_ok;
wire table_b_nb_ok;
wire table_f_cond;
wire table_f_nb_ok;
assign table_a_nb_ok = table_a && !i_nibble[3];   
assign table_b_nb_ok = table_b &&  i_nibble[3];
assign table_f_cond  = !i_nibble[3] || (i_nibble == 4'hF);
assign table_f_nb_ok = table_f && table_f_cond;
`endif

/* here we go
 */ 

always @(posedge i_clk) begin
  if (i_reset || do_on_first_nibble) begin
    // reset values
    fields_table_done <= 0;
    o_field           <= 0;
    o_field_valid     <= 0;
    case (i_nibble)
    4'h6, 4'h7: begin // GOTO / GOSUB
      o_field_start     <= 0;
      o_field_last      <= 2;
    end
    default: begin
      o_field_start     <= 0;
      o_field_last      <= 0;
    end
    endcase
  end

  /******************************************************************************
  *
  * set field for specific instructions
  *
  *****************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
    4'h6, 4'h7: begin
      // virtual A
      o_field_start <= 0;
      o_field_last  <= 4;
    end
    4'h8, 4'h9, 4'hA, 4'hB: begin
      // ST is 0-3
      o_field_start <= 0;
      o_field_last  <= 3;
    end
    default: begin end // don't care
    endcase
  end

  if (do_block_1x) begin
    o_field_start <= 0;
    case (i_nibble)
    4'h9, 4'hD: begin
      o_field_last <= 1;
    end
    4'hA, 4'hE: begin
      o_field_last <= 3;
    end
    4'hB, 4'hF: begin
      o_field_last <= 4;
    end
    endcase
  end

  if (do_block_Rn_A_C) begin
    o_field_start <= 0;
    o_field_last  <= 15;
  end

  if (do_block_13x) begin
    o_field_start <= 0;
    o_field_last  <= i_nibble[3]?3:4;
  end

  if (do_block_14x_15xx && !do_fields_table) begin
    o_field       <= i_nibble[3]?`FT_FIELD_B:`FT_FIELD_A;
    o_field_start <= 0;
    o_field_last  <= i_nibble[3]?1:4;
    o_field_valid <= 1;
  end

  if (do_block_14x_15xx && do_fields_table && table_value) begin
    o_field_start <= 0;
    o_field_last  <= i_nibble;
    o_field_valid <= 1;
  end

  if (do_block_pointer_arith_const) begin
    o_field_start <= 0;
    o_field_last  <= 4;
  end

  if (do_block_3x) begin
    o_field_start <= i_reg_p;
    o_field_last  <= (i_nibble + i_reg_p) & 4'hF;
  end

  if (do_block_8x) begin
    case (i_nibble)
      4'hC, 4'hD, 4'hE, 4'hF: begin
        o_field_start <= 0;
        o_field_last  <= i_nibble[3]?4:3;
      end
    endcase
  end

  if (do_block_80Cx) begin
    o_field_start <= i_nibble;
    o_field_last  <= i_nibble;
  end

  if (do_block_8Ax || do_block_Cx || do_block_Dx || do_block_Fx) begin
    o_field        <= `FT_FIELD_A;
    o_field_start  <= 0;
    o_field_last   <= 4;
    o_field_valid  <= 1;
  end

  if (do_block_jump_test) begin
    o_field_start <= 0;
    o_field_last <= 1;
  end

  /******************************************************************************
  *
  * set field from a table
  *
  *
  *****************************************************************************/

  `ifdef DEBUG_FIELDS_TABLE
  if (do_tables_a_f_b) begin
    // debug info
    $display("====== fields_table | table %h | nibble %b", o_fields_table, i_nibble);
    $display("table_a     : %b", table_a_nb_ok);
    $display("table_b     : %b", table_b_nb_ok);
    $display("table_f_cond: %b", table_f_cond);
    $display("table_f     : %b", table_f_nb_ok);
    // $display("table_f nbl : %h", {4{o_fields_table == `FT_TABLE_f}} );
    //$display("table_f val : %h", table_f_nibble_value);
    $display("case nibble : %h", table_a_f_b_case_value);
  end
  `endif


  // 
  if (do_tables_a_f_b) begin
    case (table_a_f_b_case_value)
    4'h0: begin 
      o_field       <= `FT_FIELD_P;
      o_field_start <= i_reg_p;
      o_field_last  <= i_reg_p;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field P (%h)", i_reg_p);
      `endif
    end
    4'h1: begin 
      o_field       <= `FT_FIELD_WP;
      o_field_start <= 0;
      o_field_last  <= i_reg_p;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field WP (0-%h)", i_reg_p);
      `endif
    end
    4'h2: begin 
      o_field       <= `FT_FIELD_XS;
      o_field_start <= 2;
      o_field_last  <= 2;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field XS");
      `endif
    end
    4'h3: begin 
      o_field       <= `FT_FIELD_X;
      o_field_start <= 0;
      o_field_last  <= 2;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field X");
      `endif
    end
    4'h4: begin 
      o_field       <= `FT_FIELD_S;
      o_field_start <= 15;
      o_field_last  <= 15;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field S");
      `endif
    end
    4'h5: begin 
      o_field       <= `FT_FIELD_M;
      o_field_start <= 3;
      o_field_last  <= 14;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field M");
      `endif
    end
    4'h6: begin 
      o_field       <= `FT_FIELD_B;
      o_field_start <= 0;
      o_field_last  <= 1;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field B");
      `endif
    end
    4'h7: begin 
      o_field       <= `FT_FIELD_W;
      o_field_start <= 0;
      o_field_last  <= 15;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field W");
      `endif
    end
    4'hF: begin
      o_field       <= `FT_FIELD_A;
      o_field_start <= 0;
      o_field_last  <= 4;
      `ifdef DEBUG_FIELDS_TABLE
      $display("fields_table: field A");
      `endif
    end
    default: begin
      o_dec_error <= 1;
      `ifdef SIM
      $display("fields_table: table %h nibble %h not handled", o_fields_table, i_nibble);
      `endif
    end
    endcase
    o_field_valid     <= 1;
    fields_table_done <= 1;
  end 
end
