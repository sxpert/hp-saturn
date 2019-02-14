/******************************************************************************
 *
 * Instruction decoder module
 *
 *****************************************************************************/

`include "def-fields.v"
`include "def-alu.v"

module saturn_decoder(
  i_clk, 
  i_reset,
  i_cycles,
  i_en_dbg,
  i_en_dec,
  i_stalled,
  i_pc,
  i_nibble,

  i_reg_p,

  o_inc_pc,
  o_push,
  o_pop,
  o_dec_error,
  o_alu_debug,
  
  o_ins_addr,
  o_ins_decoded,

  o_fields_table,
  o_field,
  o_field_valid,
  o_field_start,
  o_field_last,
  o_imm_value,

  o_alu_op,
  o_alu_no_stall,
  o_reg_dest,
  o_reg_src1,
  o_reg_src2,

  o_direction,
  o_ins_rtn,
  o_set_xm,
  o_set_carry,
  o_en_intr,
  o_test_carry,
  o_carry_val,
  o_ins_set_mode,
  o_mode_dec,
  o_ins_alu_op,

  o_dbg_nibbles,
  o_dbg_nb_nbls,
  o_mem_load,
  o_mem_pos
);

/*
 * module input / output ports
 */
input   wire [0:0]  i_clk;
input   wire [0:0]  i_reset;
input   wire [31:0] i_cycles;
input   wire        i_en_dbg;
input   wire        i_en_dec;
input   wire        i_stalled;
input   wire [19:0] i_pc;
input   wire [3:0]  i_nibble;

input   wire [3:0]  i_reg_p;

output  reg         o_inc_pc;
output  reg         o_push;
output  reg         o_pop;
output  reg         o_dec_error;
output  reg         o_alu_debug;

// instructions related outputs
output  reg [19:0]  o_ins_addr;
output  reg         o_ins_decoded;

output  reg [1:0]   o_fields_table;
output  reg [3:0]   o_field;
output  reg         o_field_valid;
output  reg [3:0]   o_field_start;
output  reg [3:0]   o_field_last;
output  reg [3:0]   o_imm_value;

output  reg [4:0]   o_alu_op;
output  reg [0:0]   o_alu_no_stall;
output  reg [4:0]   o_reg_dest;
output  reg [4:0]   o_reg_src1;
output  reg [4:0]   o_reg_src2;

// generic
output  reg         o_direction;

// rtn specific
output  reg         o_ins_rtn;
output  reg         o_set_xm;
output  reg         o_set_carry;
output  reg         o_test_carry;
output  reg         o_carry_val;
output  reg         o_en_intr;

// setdec/hex
output  reg         o_ins_set_mode;
output  reg         o_mode_dec;

// alu_operations
output  reg         o_ins_alu_op;

/* data used by the debugger
 *
 */
output  reg [(21*4-1):0] o_dbg_nibbles;
output  reg [4:0]        o_dbg_nb_nbls;
output  reg [63:0]       o_mem_load;
output  reg [4:0]        o_mem_pos;


/*
 * state registers
 */

reg [31:0]  inst_counter;
reg [0:0]   next_nibble;
reg [4:0]   inst_cycles;

reg         inval_opcode_regs;


initial begin
`ifdef SIM
  // $monitor({"i_clk %b | i_reset %b | i_cycles %d | i_en_dec %b | i_en_exec %b |",
  //          " next_nibble %b | instr_start %b | i_nibble %h"}, 
  //          i_clk, i_reset, i_cycles, i_en_dec, i_en_exec, next_nibble, 
  //          instr_start, i_nibble);
  // $monitor("i_en_dec %b | i_cycles %d | nb %h | cont %b | b0x %b | rtn %b | sxm %b | sc %b | cv %b",
  //          i_en_dec, i_cycles, i_nibble, next_nibble, block_0x, ins_rtn, set_xm, set_carry, carry_val);
`endif  
end

/*
 * debugger
 *
 */

wire [19:0] new_pc;
assign new_pc = i_pc + 1;

wire run_debugger;
assign run_debugger =  !i_reset && i_en_dbg && !i_stalled && !next_nibble;

wire is_short_transfer;
assign is_short_transfer = (o_field_last == 3) && 
                           ((o_reg_dest[4:1] == 4'b0010) || (o_reg_src1[4:1] == 4'b0010));

wire p_is_dest;
wire is_load_imm;
wire is_d0_eq;
wire is_d1_eq;
wire is_p_eq;
wire is_la_hex; 
wire is_lc_hex; 
wire disp_nb_nibbles;
assign p_is_dest       = (o_reg_dest == `ALU_REG_P);
assign is_load_imm     =   ((o_alu_op == `ALU_OP_COPY)     || 
                            (o_alu_op == `ALU_OP_RST_BIT)  ||
                            (o_alu_op == `ALU_OP_SET_BIT)  ||
                            (o_alu_op == `ALU_OP_JMP_REL3) ||
                            (o_alu_op == `ALU_OP_JMP_REL4) ||
                            (o_alu_op == `ALU_OP_JMP_ABS5))
                         && (o_reg_src1 == `ALU_REG_IMM);
assign is_d0_eq        = is_load_imm && (o_reg_dest == `ALU_REG_D0);
assign is_d1_eq        = is_load_imm && (o_reg_dest == `ALU_REG_D1);
assign is_p_eq         = is_load_imm && p_is_dest;
assign is_la_hex       = is_load_imm && (o_reg_dest == `ALU_REG_A);
assign is_lc_hex       = is_load_imm && (o_reg_dest == `ALU_REG_C);
assign disp_nb_nibbles = is_d0_eq || is_d1_eq;

reg [4:0]  nibble_pos;

always @(posedge i_clk) begin
  if (run_debugger) begin
    /*
     * this whole thing is a large print statement
     * THIS PART IS NEVER GENERATED
     */
    `ifdef SIM
    if (o_ins_decoded) begin
      $write("DBG[%5d]: ", inst_counter);
      $write("%5h ", o_ins_addr);

      // $write("[%2d] ", o_dbg_nb_nbls);

      for(nibble_pos=0; nibble_pos!=o_dbg_nb_nbls; nibble_pos=nibble_pos+1)
        $write("%h", o_dbg_nibbles[nibble_pos*4+:4]);
      for(nibble_pos=o_dbg_nb_nbls; nibble_pos!=22; nibble_pos=nibble_pos+1)
        $write(" ");

      // display decoded instruction
      if (o_ins_rtn) begin
        $write("RT%s", o_en_intr?"I":"N");
        if (o_set_xm) $write("SXM");
        if (o_set_carry) $write("%sC", o_carry_val?"S":"C");
      end
      if (o_ins_set_mode) begin
        $write("SET%s", o_mode_dec?"DEC":"HEX");
      end
      if (o_ins_alu_op) begin
        
        case (o_alu_op)
          `ALU_OP_JMP_REL3:  $write("GOTO"); 
          `ALU_OP_JMP_REL4:  $write("%s", o_push?"GOSUBL":"GOLONG");
          `ALU_OP_JMP_ABS5:  $write("%s", o_push?"GOSBVL":"GOVLNG");
          `ALU_OP_CLR_MASK:
            case (o_reg_dest)
              `ALU_REG_HST:
                case (o_imm_value)
                  4'h1: $write("XM=0");
                  4'h2: $write("SB=0");
                  4'h4: $write("SR=0");
                  4'h8: $write("MP=0");
                  default: begin  
                    $write("CLRHST");
                    if (o_imm_value != 4'hF) $write("\t%1h", o_imm_value);
                  end
                endcase
              default:         $write("[VLR_MASK dest:%0d]", o_reg_dest);
            endcase  
          default:
            case (o_reg_dest)
            `ALU_REG_A:      $write("A");
            `ALU_REG_B:      $write("B");
            `ALU_REG_C:    
              if (is_lc_hex) $write("LCHEX");
              else $write("C");
            `ALU_REG_D:      $write("D");
            `ALU_REG_D0:     $write("D0");
            `ALU_REG_D1:     $write("D1");
            `ALU_REG_RSTK:   $write("RSTK");
            `ALU_REG_R0:     $write("R0");
            `ALU_REG_R1:     $write("R1");
            `ALU_REG_R2:     $write("R2");
            `ALU_REG_R3:     $write("R3");
            `ALU_REG_R4:     $write("R4");
            `ALU_REG_DAT0:   $write("DAT0");
            `ALU_REG_DAT1:   $write("DAT1");
            `ALU_REG_ST:     if (o_alu_op!=`ALU_OP_ZERO) $write("ST");
            `ALU_REG_P:      $write("P");
            default:         $write("[dest:%0d]", o_reg_dest);
            endcase
        endcase

        case (o_alu_op)
        `ALU_OP_ZERO:     if (o_reg_dest==`ALU_REG_ST) 
                            $write("CLRST"); 
                          else $write("=0");
        `ALU_OP_COPY,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_INC,
        `ALU_OP_DEC,
        `ALU_OP_ADD,
        `ALU_OP_SUB,
        `ALU_OP_RST_BIT,
        `ALU_OP_SET_BIT:  if (!is_lc_hex) 
                            $write("=");
        `ALU_OP_2CMPL:    $write("=-");
        `ALU_OP_EXCH,
        `ALU_OP_JMP_REL3,
        `ALU_OP_JMP_REL4,
        `ALU_OP_JMP_ABS5,
        `ALU_OP_CLR_MASK: begin end
        default: $write("[op:%0d]", o_alu_op);
        endcase
        
        case (o_alu_op)
        `ALU_OP_COPY,
        `ALU_OP_EXCH,
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_INC,
        `ALU_OP_DEC,
        `ALU_OP_ADD,
        `ALU_OP_SUB,
        `ALU_OP_2CMPL:
          case (o_reg_src1)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_D0:   $write("D0");
          `ALU_REG_D1:   $write("D1");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_R0:   $write("R0");
          `ALU_REG_R1:   $write("R1");
          `ALU_REG_R2:   $write("R2");
          `ALU_REG_R3:   $write("R3");
          `ALU_REG_R4:   $write("R4");
          `ALU_REG_DAT0: $write("DAT0");
          `ALU_REG_DAT1: $write("DAT1");
          `ALU_REG_ST:   $write("ST");
          `ALU_REG_P:    $write("P");
          `ALU_REG_IMM: 
            if (disp_nb_nibbles) $write("(%0d)", o_mem_pos+1);
          default: $write("[src1:%0d]", o_reg_src1);
          endcase
        `ALU_OP_RST_BIT: $write("0");
        `ALU_OP_SET_BIT: $write("1");
        endcase

        if ((o_alu_op == `ALU_OP_COPY) && is_short_transfer) 
          $write("S");

        if (o_alu_op == `ALU_OP_EXCH)
          $write("%s", is_short_transfer?"XS":"EX");

        case (o_alu_op)
        `ALU_OP_AND,
        `ALU_OP_OR,
        `ALU_OP_ADD,
        `ALU_OP_SUB: begin
          case (o_alu_op)
          `ALU_OP_AND: $write("&");
          `ALU_OP_OR:  $write("!");
          `ALU_OP_ADD:  $write("+");
          `ALU_OP_SUB:  $write("-");
          default: $write("[op:%0d]", o_alu_op);
          endcase
          
          case (o_reg_src2)
          `ALU_REG_A:    $write("A");
          `ALU_REG_B:    $write("B");
          `ALU_REG_C:    $write("C");
          `ALU_REG_D:    $write("D");
          `ALU_REG_RSTK: $write("RSTK");
          `ALU_REG_IMM:  $write("\t%0d", o_imm_value+1);
          default:       $write("[src2:%0d]", o_reg_src2);
          endcase
        end
        `ALU_OP_INC:  $write("+1");
        `ALU_OP_DEC:  $write("-1");
        `ALU_OP_ZERO,
        `ALU_OP_COPY,
        `ALU_OP_EXCH: begin end
        endcase
        
        // if (!((o_reg_dest == `ALU_REG_RSTK) || (o_reg_src1 == `ALU_REG_RSTK) ||
        //       (o_reg_dest == `ALU_REG_ST)   || (o_reg_src1 == `ALU_REG_ST  ) ||
        //       (o_reg_dest == `ALU_REG_P)    || (o_reg_src1 == `ALU_REG_P   ))) begin
        $write("\t");
        if (o_field_valid) begin
          
          // $write("[FT%d]", o_fields_table);
          if (o_fields_table != `FT_TABLE_value)
            case (o_field)
            `FT_FIELD_P:  $write("P");
            `FT_FIELD_WP: $write("WP");
            `FT_FIELD_XS: $write("XS");
            `FT_FIELD_X:  $write("X");
            `FT_FIELD_S:  $write("S");
            `FT_FIELD_M:  $write("M");
            `FT_FIELD_B:  $write("B");
            `FT_FIELD_W:  $write("W");
            `FT_FIELD_A:  $write("A");
            endcase
          else $write("%0d", o_field_last+1);
        end else begin
          // $write("@%b@", is_load_imm);
          if (is_load_imm) begin
            if (is_p_eq) $write("%0d", o_imm_value);
            else
              for(nibble_pos=(o_mem_pos - 1); nibble_pos!=31; nibble_pos=nibble_pos-1)
                $write("%h", o_mem_load[nibble_pos*4+:4]);
          end
          else 
            case (o_reg_dest)
            `ALU_REG_P,
            `ALU_REG_ST,
            `ALU_REG_HST: begin end
            `ALU_REG_C:  
              if (o_reg_src1 == `ALU_REG_P)
                $write("%0d", o_field_start);
            default: $write("[%h:%h]", o_field_start, o_field_last);
            endcase
        end
      end
      $display("\t(%0d cycles)", inst_cycles);
    end
    // $display("new [%5h]--------------------------------------------------------------------", new_pc);  
    `endif
  end
end

/******************************************************************************
 *
 * handles part of the instruction decoding,  
 * acts as the main FSM
 *
 *****************************************************************************/

// general variables
reg   use_fields_tbl;

reg   block_0x;
reg   block_0Efx;
reg   block_1x;
reg   block_save_to_R_W;
reg   block_rest_from_R_W;
reg   block_exch_with_R_W;
reg   block_pointer_assign_exch;
reg   block_mem_transfer;
reg   block_pointer_arith_const;
reg   block_load_p;
reg   block_load_c_hex;
reg   block_jmp2_cry_set;
reg   block_jmp2_cry_clr;

reg   block_8x;
reg   block_80x;
reg   block_80Cx;
reg   block_82x;

reg   block_Fx;

reg   go_fields_table;

/* lots'o-wires to decode common states
 */

wire  count_cycles;
wire  decoder_active;
wire  decoder_stalled;
wire  do_on_first_nibble;
wire  do_on_other_nibbles;

assign count_cycles        = !i_reset && i_en_dec && (next_nibble || i_stalled);
assign decoder_active      = !i_reset && i_en_dec && !i_stalled;
assign decoder_stalled     = !i_reset && i_en_dec &&  i_stalled;
assign do_on_first_nibble  = decoder_active && !next_nibble;
assign do_on_other_nibbles = decoder_active && next_nibble;

wire  do_block_0x;
wire  do_block_0Efx;
wire  do_block_1x;
wire  do_block_save_to_R_W;
wire  do_block_rest_from_R_W;
wire  do_block_exch_with_R_W;
wire  do_block_Rn_A_C;
wire  do_block_pointer_assign_exch;
wire  do_block_mem_transfer;
wire  do_block_pointer_arith_const;
wire  do_block_load_p;
wire  do_block_load_c_hex;

wire  do_block_8x;
wire  do_block_80x;
wire  do_block_80Cx;
wire  do_block_82x;
wire  do_block_Fx;

assign do_block_0x                  = do_on_other_nibbles && block_0x;
assign do_block_0Efx                = do_on_other_nibbles && block_0Efx;
assign do_block_1x                  = do_on_other_nibbles && block_1x;
assign do_block_save_to_R_W         = do_on_other_nibbles && block_save_to_R_W;                  
assign do_block_rest_from_R_W       = do_on_other_nibbles && block_rest_from_R_W;       
assign do_block_exch_with_R_W       = do_on_other_nibbles && block_exch_with_R_W;    
assign do_block_Rn_A_C              = do_on_other_nibbles && 
                                      ( block_save_to_R_W   ||
                                        block_rest_from_R_W ||
                                        block_exch_with_R_W );
assign do_block_pointer_assign_exch = do_on_other_nibbles && block_pointer_assign_exch; 
assign do_block_mem_transfer        = do_on_other_nibbles && block_mem_transfer;        
assign do_block_pointer_arith_const = do_on_other_nibbles && block_pointer_arith_const; 
assign do_block_load_p              = do_on_other_nibbles && block_load_p;
assign do_block_load_c_hex          = do_on_other_nibbles && block_load_c_hex;

assign do_block_8x                  = do_on_other_nibbles && block_8x;
assign do_block_80x                 = do_on_other_nibbles && block_80x;
assign do_block_80Cx                = do_on_other_nibbles && block_80Cx;
assign do_block_82x                 = do_on_other_nibbles && block_82x;

assign do_block_Fx                  = do_on_other_nibbles && block_Fx;

/*
 * subroutines
 */

reg  block_load_reg_imm;
reg  block_jmp;
reg  block_sr_bit;
wire do_load_reg_imm;
wire do_block_jmp;
wire do_block_sr_bit;
assign do_load_reg_imm = do_on_other_nibbles && block_load_reg_imm;
assign do_block_jmp    = do_on_other_nibbles && block_jmp;
assign do_block_sr_bit = do_on_other_nibbles && block_sr_bit;

wire in_fields_table;
assign in_fields_table = go_fields_table && !fields_table_done;

/*
 * variables specific to a particular use
 */

reg [4:0]   mem_load_max;

/* most instructions are groupped by sets of 4 with
 * varrying series of registers that are common
 * this generates all the required series from i_nibble
 */

wire [4:0]   dbg_write_pos;
assign dbg_write_pos = (!next_nibble?0:o_dbg_nb_nbls);

always @(posedge i_clk) begin
  if (i_reset) begin
    inst_cycles    <= 0;
    inst_counter   <= 0;
    next_nibble    <= 0;
    use_fields_tbl <= 0;
    o_inc_pc       <= 1;
    o_dec_error    <= 0;
    o_alu_debug    <= 0;
    o_ins_decoded  <= 0;
    o_alu_op       <= 0;
  end
  
  if (decoder_active) begin
    /* 
      * stuff that is always done
      */
    `ifdef SIM
    // $display("DEC_RUN  2: nibble %h", i_nibble);
    `endif
    o_inc_pc                          <= 1; // may be set to 0 later
    o_dbg_nibbles[dbg_write_pos*4+:4] <= i_nibble;
    o_dbg_nb_nbls                     <= o_dbg_nb_nbls + 1;
  end

  // if (decoder_stalled) begin
  //   $display("DEC_STAL 2:");
  // end

  if (count_cycles) begin
    inst_cycles <= inst_cycles + 1;
  end

    /*
      * cleanup
      */ 
  if (do_on_first_nibble) begin
    inst_counter    <= inst_counter + 1;
    inst_cycles     <= 1;
    next_nibble     <= 1;
    use_fields_tbl  <= 0;
    o_alu_debug     <= 0;

    o_push          <= 0;
    o_pop           <= 0;

    o_ins_decoded   <= 0;
    // store the address where the instruction starts
    o_ins_addr      <= i_pc;

    // decoder block states

    block_0x                   <= 0;
    block_0Efx                 <= 0;
    block_1x                   <= 0;
    block_save_to_R_W          <= 0;
    block_rest_from_R_W        <= 0;
    block_exch_with_R_W        <= 0;
    block_pointer_assign_exch  <= 0;
    block_mem_transfer         <= 0;
    block_pointer_arith_const  <= 0;
    block_load_p               <= 0;
    block_load_c_hex           <= 0;

    block_8x                   <= 0;
    block_80x                  <= 0;
    block_80Cx                 <= 0;
    block_82x                  <= 0;
    block_Fx                   <= 0;

    // decoder subroutine states

    block_load_reg_imm         <= 0;
    block_jmp                  <= 0;
    block_sr_bit               <= 0;

    // cleanup fields table variables
    go_fields_table <= 0;
    o_fields_table  <= 3;
    o_field         <= 0;
    o_field_start   <= 0;
    o_field_last    <= 0;

    o_alu_op        <= 0;
    o_alu_no_stall  <= 0;

    // cleanup
    o_direction     <= 0;

    o_ins_rtn       <= 0;
    o_set_xm        <= 0;
    o_set_carry     <= 0;
    o_carry_val     <= 0;
    
    o_ins_set_mode  <= 0;
    o_mode_dec      <= 0;

    o_ins_alu_op    <= 0;

    o_dbg_nb_nbls   <= 1;
    o_mem_pos       <= 0;

    /*
      * x first nibble
      */

    // assign block regs
    case (i_nibble) 
    4'h0: block_0x            <= 1;
    4'h1: block_1x            <= 1;
    4'h2: block_load_p        <= 1;
    4'h3: block_load_c_hex    <= 1;
    4'h4, 4'h5: begin 
      // 400 RTNC
      // 420 NOP3
      // 4xy GOC
      // 500 RTNNC
      // 5xy GONC
      o_alu_no_stall <= 1;
      o_alu_op       <= `ALU_OP_JMP_REL2;
      mem_load_max   <= 1;
      o_mem_pos      <= 0;
      o_test_carry   <= 1;
      o_carry_val    <= !i_nibble[0];
      block_jmp      <= 1;
    end
    4'h6, 4'h7: begin
      o_alu_no_stall <= 1;
      o_alu_op       <= `ALU_OP_JMP_REL3;
      mem_load_max   <= 2;
      o_mem_pos      <= 0;
      o_push         <= i_nibble[0];  
      block_jmp      <= 1;
    end
    4'h8: block_8x   <= 1;
    4'hF: block_Fx   <= 1;
    default: begin
      `ifdef SIM
      $display("DEC_INIT 2: nibble %h not handled", i_nibble);
      `endif
      o_dec_error <= 1;
    end
    endcase
  end


  /******************************************************************************
  *
  * 0x
  *
  * 00   RTNSXM        08   CLRST
  * 01   RTN           09   C=ST
  * 02   RTNSC         0A   ST=C
  * 03   RTNCC         0B   CSTEX
  * 04   SETHEX        0C   P=P+1
  * 05   SETDEC        0D   P=P-1
  * 06   RSTK=C
  * 07   C=RSTK        0F   RTI
  *
  *****************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
    4'h0, 4'h1, 4'h2, 4'h3, 4'hF: begin
      o_ins_rtn      <= 1;
      o_set_xm       <=  i_nibble == 4'h0;
      o_set_carry    <= !i_nibble[3] && i_nibble[1];
      o_carry_val    <=  i_nibble[1] && i_nibble[0];
      o_en_intr      <=  i_nibble[3];
    end
    4'h4, 4'h5: begin
      o_ins_set_mode <= 1;
      o_mode_dec     <= (i_nibble[0]);
    end
    /* RSTK=C
    * C=RSTK
    * those 2 are alu copy ops between RSTK and C
    */
    4'h6, 4'h7: begin 
      o_ins_alu_op   <= 1;
      o_alu_op       <= `ALU_OP_COPY;
      o_push         <= !i_nibble[0];
      o_pop          <=  i_nibble[0];
    end
    4'h8: begin
      o_ins_alu_op <= 1;
      o_alu_op     <= `ALU_OP_ZERO;
    end
    4'h9, 4'hA: begin
      o_ins_alu_op <= 1;
      o_alu_op     <= `ALU_OP_COPY;
    end
    4'hB: begin
      o_ins_alu_op <= 1;
      o_alu_op     <= `ALU_OP_EXCH;
    end
    4'hC, 4'hD: begin
      o_ins_alu_op <= 1;
      o_alu_op     <= i_nibble[0]?`ALU_OP_DEC:`ALU_OP_INC;
    end
    4'hE: begin
      block_0x <= 0;
      o_fields_table <= `FT_TABLE_f;
    end
    default: begin
      `ifdef SIM
      $display("block_0x: nibble %h not handled", i_nibble);
      `endif
      o_dec_error <= 1;
    end
    endcase
    next_nibble     <= (i_nibble == 4'hE);
    block_0Efx      <= (i_nibble == 4'hE);
    go_fields_table <= (i_nibble == 4'hE);
    o_ins_decoded   <= (i_nibble != 4'hE);
  end 

  /******************************************************************************
  *
  * 0Ex   R1=R1[&!]R2    table_f
  *
  *****************************************************************************/

  if (do_block_0Efx && !in_fields_table) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= (!i_nibble[3])?`ALU_OP_AND:`ALU_OP_OR;
    next_nibble   <= 0;
    o_ins_decoded <= 1;
  end

  /******************************************************************************
  *
  * 1x   jump table to other things
  *
  *****************************************************************************/

  if (do_block_1x) begin
    case (i_nibble)
      4'h0:       // save     A/C to   Rn W
        block_save_to_R_W         <= 1;
      4'h1:       // restore  A/C from Rn W 
        block_rest_from_R_W       <= 1;
      4'h2:       // exchange A/C with Rn W
        block_exch_with_R_W       <= 1;
      4'h3:       // move/exch A/C with Dn A/[0:3]
        block_pointer_assign_exch <= 1;
      4'h4, 4'h5: // DAT[01]=[AC] <field>
      begin
        block_mem_transfer        <= 1;
        o_fields_table  <= i_nibble[0]?`FT_TABLE_value:`FT_TABLE_f;
        use_fields_tbl            <= i_nibble[0];
      end
      4'h6, 4'h7, 
      4'h8, 4'hC: // D[01]=D[01][+-]  n+1;
      begin
        block_pointer_arith_const <= 1;
        o_ins_alu_op              <= 1;
        o_alu_op                  <= i_nibble[1]?`ALU_OP_ADD:`ALU_OP_SUB;
      end
      4'h9, 4'hA, 
      4'hB, 4'hD, 
      4'hE, 4'hF: // D[0]=([245]) <stuff>    
      begin
        mem_load_max              <= {2'b00, i_nibble[1], !i_nibble[1], i_nibble[1] && i_nibble[0]};
        o_mem_pos                 <= 0;
        block_load_reg_imm        <= 1;
        o_alu_no_stall            <= 1;
        o_alu_op                  <= `ALU_OP_COPY;
      end
    endcase
    block_1x <= 0;
  end

  if (do_block_save_to_R_W || do_block_rest_from_R_W) begin
    o_ins_alu_op        <= 1;
    o_alu_op            <= `ALU_OP_COPY;
    next_nibble         <= 0;
    o_ins_decoded       <= 1;
    block_save_to_R_W   <= 0;
    block_rest_from_R_W <= 0;
  end

  if (do_block_exch_with_R_W) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= `ALU_OP_EXCH;
    next_nibble      <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_pointer_assign_exch) begin
    o_ins_alu_op  <= 1;
    o_alu_op      <= i_nibble[1]?`ALU_OP_EXCH:`ALU_OP_COPY;
    next_nibble      <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_mem_transfer) begin
    o_ins_alu_op    <= 1;
    o_alu_op        <= `ALU_OP_COPY;
    // we next_nibble if we need the fields table (nibble2 was 5)
    go_fields_table <= use_fields_tbl;
    next_nibble     <= use_fields_tbl;
    use_fields_tbl  <= 0;
    o_ins_decoded   <= !(use_fields_tbl);
  end

  if (do_block_pointer_arith_const) begin
    next_nibble     <= 0;
    o_imm_value     <= i_nibble;
    o_ins_decoded   <= 1;
  end

  if (do_block_load_p) begin
    o_ins_alu_op    <= 1;
    o_alu_op        <= `ALU_OP_COPY;
    o_imm_value   <= i_nibble;
    next_nibble   <= 0;
    o_ins_decoded <= 1;
  end

  if (do_block_load_c_hex) begin
    // $write("block load C hex %h\n", i_nibble);
    mem_load_max       <= i_nibble + 1;
    o_mem_pos          <= 0;
    o_alu_no_stall     <= 1;
    o_alu_op           <= `ALU_OP_COPY;
    block_load_reg_imm <= 1;
    block_load_c_hex   <= 0;
  end


  if (do_block_8x) begin
    $display("block_8x %h | op %d", i_nibble, o_alu_op);
    case (i_nibble)
      4'h0:       // 
        block_80x  <= 1;
      4'h2: 
        block_82x  <= 1;
      4'h4, 4'h5: // ST=[01] n
      begin 
        o_alu_op       <= i_nibble[0]?`ALU_OP_SET_BIT:`ALU_OP_RST_BIT;
        block_sr_bit   <= 1;
      end
      4'hC, 4'hD, 
      4'hE, 4'hF: // GOLONG, GOVLNG, GOSUBL, GOSBVL
      begin
        o_alu_no_stall <= 1;
        o_alu_op       <= i_nibble[0]?`ALU_OP_JMP_ABS5:`ALU_OP_JMP_REL4;
        // is it a gosub ?
        o_push         <= i_nibble[1];
        o_alu_debug    <= i_nibble[1];
        mem_load_max   <= i_nibble[0]?4:3;
        o_mem_pos      <= 0;
        block_jmp      <= 1;
        // debug for cases not tested
        o_alu_debug    <= !i_nibble[0];     
      end
      default: begin
        $display("block_8x %h error", i_nibble);
        o_dec_error    <= 1;
      end
    endcase
    block_8x           <= 0;
  end

  if (do_block_80x) begin
    $display("block_80x %h | op %d", i_nibble, o_alu_op);
    case (i_nibble)
      4'hA: begin // RESET
        next_nibble   <= 0;
        o_ins_decoded <= 1;
      end
      4'hC: block_80Cx <= 1;
      default: begin
        $display("block_80x %h error", i_nibble);
        o_dec_error    <= 1;
      end
    endcase
    block_80x          <= 0;
  end

  if (do_block_80Cx) begin
    o_ins_alu_op   <= 1;
    o_alu_op       <= `ALU_OP_COPY;
    next_nibble    <= 0;
    o_ins_decoded  <= 1;
  end

  // 821 XM=0
  // 822 SB=0
  // 824 SR=0
  // 828 MP=0
  // 82F CLRHST
  // 82x CLRHST     x
  if (do_block_82x) begin
    o_ins_alu_op   <= 1;
    o_alu_op       <= `ALU_OP_CLR_MASK;
    o_imm_value    <= i_nibble;
    next_nibble    <= 0;
    o_ins_decoded  <= 1;
  end


  if (do_block_Fx) begin
    case (i_nibble)
      4'h8, 4'h9, 4'hA, 4'hB: // r=-r   A
      begin
        o_fields_table <= `FT_TABLE_f;
        //o_alu_debug    <= 1;
        o_ins_alu_op   <= 1;
        o_alu_op       <= `ALU_OP_2CMPL;
        next_nibble    <= 0;
        o_ins_decoded  <= 1;      
      end
      default: begin
        $display("block_Fx %h error", i_nibble);
        o_dec_error    <= 1;
      end
    endcase
    block_Fx           <= 0;
  end

  // utilities

  if (do_load_reg_imm) begin
    // $write("load reg imm %h | ", i_nibble);
    // $write("pos %d | max %d | ", o_mem_pos, mem_load_max);
    // $write("next %b | dec %b | ", (o_mem_pos+1) != mem_load_max, (o_mem_pos+1) == mem_load_max);
    // $write("\n");
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[o_mem_pos*4+:4] <= i_nibble;
    o_mem_pos                  <= o_mem_pos + 1;
    next_nibble                <= (o_mem_pos+1) != mem_load_max;
    o_ins_decoded              <= (o_mem_pos+1) == mem_load_max;
  end

  if (do_block_jmp) begin
    $display("do_block_jmp %h", i_nibble);
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[o_mem_pos*4+:4] <= i_nibble;
    o_mem_pos                  <= o_mem_pos + 1;
    next_nibble                <= mem_load_max != o_mem_pos;
    o_ins_decoded              <= mem_load_max == o_mem_pos;
  end

  if (do_block_sr_bit) begin
    $display("do_block_sr_bit %h", i_nibble);
    o_ins_alu_op               <= 1;
    o_imm_value                <= i_nibble;
    o_mem_load[3:0]            <= i_nibble;
    o_mem_pos                  <= 1;
    next_nibble                <= 0;
    o_ins_decoded              <= 1;
  end

end


/******************************************************************************
*
* set registers from instruction nibble
*
*****************************************************************************/

wire [4:0]		reg_ABCD;
wire [4:0]		reg_BCAC;
wire [4:0]		reg_ABAC;
wire [4:0]		reg_BCCD;
wire [4:0]		reg_D0D1;
wire [4:0]		reg_DAT0DAT1;
wire [4:0]    reg_A_C;

assign reg_ABCD     = { 3'b000,   i_nibble[1:0]};
assign reg_BCAC     = { 3'b000,   i_nibble[0], !(i_nibble[1] ||   i_nibble[0])};
assign reg_ABAC     = { 3'b000,   i_nibble[1] && i_nibble[0],   (!i_nibble[1]) && i_nibble[0]};
assign reg_BCCD     = { 3'b000,   i_nibble[1] || i_nibble[0],   (!i_nibble[1]) ^  i_nibble[0]};
// assign reg_D0D1 = { 4'b0010, (i_nibble[0] && i_nibble[1]) || (i_nibble[2]  && i_nibble[3])};
assign reg_D0D1     = { 4'b0010,  i_nibble[0]};
assign reg_DAT0DAT1 = { 4'b1000,  i_nibble[0]};
assign reg_A_C      = { 3'b000,   i_nibble[2],   1'b0};

always @(posedge i_clk) begin

  if (i_reset) begin
    o_reg_dest        <= 0;
    o_reg_src1        <= 0;
    o_reg_src2        <= 0;
    inval_opcode_regs <= 0;
  end

  if (do_on_first_nibble) begin
    // reset values on instruction decode start
    case (i_nibble)
    4'h6: begin
      o_reg_dest        <= 0;
      o_reg_src1        <= `ALU_REG_IMM;
      o_reg_src2        <= 0;
    end
    default: begin
      o_reg_dest        <= 0;
      o_reg_src1        <= 0;
      o_reg_src2        <= 0;
    end
    endcase
    inval_opcode_regs <= 0;
  end


  /************************************************************************
  *
  * set registers for specific instructions
  *
  ************************************************************************/

  if (do_block_0x) begin
    case (i_nibble)
    4'h6: begin
      o_reg_dest <= `ALU_REG_RSTK;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'h7: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_RSTK;
    end
    4'h8: o_reg_dest <= `ALU_REG_ST;
    4'h9, 4'hB: begin
      o_reg_dest <= `ALU_REG_C;
      o_reg_src1 <= `ALU_REG_ST;
    end
    4'hA: begin
      o_reg_dest <= `ALU_REG_ST;
      o_reg_src1 <= `ALU_REG_C;
    end
    4'hC, 4'hD: begin
      o_reg_dest <= `ALU_REG_P;
      o_reg_src1 <= `ALU_REG_P;
    end
    default: begin
      // inval_opcode_regs <= 1;
    end
    endcase
  end 

  if (do_block_0Efx && !in_fields_table) begin
    o_reg_dest <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src1 <= i_nibble[2]?reg_BCAC:reg_ABCD;
    o_reg_src2 <= i_nibble[2]?reg_ABCD:reg_BCAC;
  end   

  if (do_block_1x) begin
    case (i_nibble)
      4'h6, 4'h8: begin
        o_reg_dest <= `ALU_REG_D0;
        o_reg_src1 <= `ALU_REG_D0; 
      end
      4'h7, 4'hC: begin
        o_reg_dest <= `ALU_REG_D1;
        o_reg_src1 <= `ALU_REG_D1; 
      end
      4'h9, 4'hA, 4'hB: begin
        o_reg_dest <= `ALU_REG_D0;
        o_reg_src1 <= `ALU_REG_IMM;
      end
      4'hD, 4'hE, 4'hF: begin
        o_reg_dest <= `ALU_REG_D1;
        o_reg_src1 <= `ALU_REG_IMM;
      end
    default: begin end
    endcase
  end

  if (do_block_save_to_R_W) begin
    o_reg_dest <= {2'b01,  i_nibble[2:0]};
    o_reg_src1 <= {3'b000, i_nibble[3]?2'b10:2'b00};
  end
  
  if (do_block_rest_from_R_W || do_block_exch_with_R_W) begin
    o_reg_dest <= {3'b000, i_nibble[3]?2'b10:2'b00};
    o_reg_src1 <= {2'b01,  i_nibble[2:0]};
  end

  if (do_block_pointer_assign_exch) begin
    o_reg_dest <= i_nibble[1]?reg_A_C:reg_D0D1;
    o_reg_src1 <= i_nibble[1]?reg_D0D1:reg_A_C;
  end

  if (do_block_mem_transfer) begin
    o_reg_dest <= i_nibble[1]?reg_A_C:reg_DAT0DAT1;
    o_reg_src1 <= i_nibble[1]?reg_DAT0DAT1:reg_A_C;
  end

  if (do_block_pointer_arith_const) begin
    o_reg_src2 <= `ALU_REG_IMM;
  end

  if (do_block_load_p) begin
    o_reg_dest <= `ALU_REG_P;
    o_reg_src1 <= `ALU_REG_IMM;
  end

  if (do_block_load_c_hex) begin
    o_reg_dest <= `ALU_REG_C;
    o_reg_src1 <= `ALU_REG_IMM;
  end

  if (do_block_8x) begin
    case (i_nibble)
      4'h4, 4'h5, 4'h6, 4'h7: begin
        o_reg_dest        <= `ALU_REG_ST;
        o_reg_src1        <= `ALU_REG_IMM;
      end
      4'hC, 4'hD, 4'hE, 4'hF: begin
        o_reg_dest        <= 0;
        o_reg_src1        <= `ALU_REG_IMM;
        o_reg_src2        <= 0;
      end
    endcase
  end

  if (do_block_80Cx) begin
    o_reg_dest        <= `ALU_REG_C;
    o_reg_src1        <= `ALU_REG_P;
    o_reg_src2        <= 0;
  end

  if (do_block_82x) begin
    o_reg_dest        <= `ALU_REG_HST;
    o_reg_src1        <= `ALU_REG_HST;
    o_reg_src2        <= `ALU_REG_IMM;
  end

  if (do_block_Fx) begin
    case (i_nibble)
      4'h8, 4'h9, 4'hA, 4'hB: begin
        o_reg_dest        <= reg_ABCD;
        o_reg_src1        <= reg_ABCD;
        o_reg_src2        <= 0;     
      end
    endcase
  end

end


/******************************************************************************
*
* set fields from instruction nibble
*
*****************************************************************************/

`ifdef SIM
// `define DEBUG_FIELDS_TABLE
`endif

reg fields_table_done;

/* more wires to decode common states.
 * can possibly be made less redundant / faster ?
 */

wire do_fields_table;
assign do_fields_table = decoder_active && go_fields_table && !fields_table_done;

wire table_a;
wire table_b;
wire table_f;
wire table_value;
assign table_a     = (o_fields_table == `FT_TABLE_a);
assign table_b     = (o_fields_table == `FT_TABLE_b);
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

wire table_a_nb_ok;
wire table_b_nb_ok;
wire table_f_cond;
wire table_f_nb_ok;
wire table_a_f_b_nb_ok;
assign table_a_nb_ok = table_a && !i_nibble[3];   
assign table_b_nb_ok = table_b &&  i_nibble[3];
assign table_f_cond  = !i_nibble[3] || (i_nibble == 4'hF);
assign table_f_nb_ok = table_f && table_f_cond;
assign table_a_f_b_nb_ok = table_a_nb_ok || table_b_nb_ok || table_f_nb_ok;

/* here we go
 */ 

always @(posedge i_clk) begin
  if (i_reset || do_on_first_nibble) begin
    // reset values
    fields_table_done <= 0;
    o_field           <= 0;
    o_field_valid     <= 0;
    case (i_nibble)
    4'h6: begin 
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

  if (do_block_pointer_assign_exch) begin
    o_field_start <= 0;
    o_field_last  <= i_nibble[3]?3:4;
  end

  if (do_block_mem_transfer && !do_fields_table) begin
    o_field       <= i_nibble[3]?`FT_FIELD_B:`FT_FIELD_A;
    o_field_start <= 0;
    o_field_last  <= i_nibble[3]?1:4;
    o_field_valid <= 1;
  end

  if (do_block_mem_transfer && do_fields_table && table_value) begin
    o_field_start <= 0;
    o_field_last  <= i_nibble;
    o_field_valid <= 1;
  end

  if (do_block_pointer_arith_const) begin
    o_field_start <= 0;
    o_field_last  <= 4;
  end

  if (do_block_load_c_hex) begin
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

  if (do_block_Fx) begin
    case (i_nibble)
      4'h8, 4'h9, 4'hA, 4'hB: begin
        o_field        <= `FT_FIELD_A;
        o_field_start  <= 0;
        o_field_last   <= 4;
        o_field_valid  <= 1;
      end
    endcase
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


endmodule