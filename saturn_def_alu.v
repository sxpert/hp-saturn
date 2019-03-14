`ifndef _DEF_ALU
`define _DEF_ALU

// stuff (where should that go ?)
`define T_SET            0
`define T_TEST           1

`define T_DIR_OUT	     0
`define T_DIR_IN		 1

`define T_PTR_0		     0
`define T_PTR_1		     1


`define FT_NONE          0
`define FT_A_B           1
`define FT_F             2
`define FT_FIELD_P       0
`define FT_FIELD_WP      1
`define FT_FIELD_XS      2
`define FT_FIELD_X       3
`define FT_FIELD_S       4
`define FT_FIELD_M       5 
`define FT_FIELD_B       6
`define FT_FIELD_W       7
`define FT_FIELD_NONE   14
`define FT_FIELD_A      15


/*
 * 
 * Opcodes for the ALU
 *
 */

// copy / exchange
`define ALU_OP_ZERO      0
`define ALU_OP_COPY      1
`define ALU_OP_EXCH      2
// shifts
`define ALU_OP_SHL       3
`define ALU_OP_SHR       4
// logic
`define ALU_OP_AND       5
`define ALU_OP_OR        6
// bit set/reset
`define ALU_OP_RST_BIT   7
`define ALU_OP_SET_BIT   8
// arithmetic
`define ALU_OP_2CMPL     9
`define ALU_OP_1CMPL    10
`define ALU_OP_INC      11
`define ALU_OP_DEC      12
`define ALU_OP_ADD      13
`define ALU_OP_SUB      14
// tests
`define ALU_OP_TEST_EQ  15
`define ALU_OP_TEST_NEQ 16
// relative jump
`define ALU_OP_JMP_REL2 17
`define ALU_OP_JMP_REL3 18
`define ALU_OP_JMP_REL4 19
`define ALU_OP_JMP_ABS5 20
`define ALU_OP_CLR_MASK 21

`define ALU_OP_SET_CRY  28
`define ALU_OP_TEST_GO  30
`define ALU_OP_NOP      31

/*
 * 
 * Registers
 *
 */

`define ALU_REG_A        0
`define ALU_REG_B        1
`define ALU_REG_C        2
`define ALU_REG_D        3
`define ALU_REG_D0       4
`define ALU_REG_D1       5
`define ALU_REG_PC       6
`define ALU_REG_RSTK     7
`define ALU_REG_R0       8
`define ALU_REG_R1       9
`define ALU_REG_R2      10
`define ALU_REG_R3      11
`define ALU_REG_R4      12
                      //13
                      //14
                      //15
`define ALU_REG_DAT0    16
`define ALU_REG_DAT1    17
`define ALU_REG_HST     18
`define ALU_REG_ST      19
`define ALU_REG_P       20
`define ALU_REG_M       21
`define ALU_REG_IMM     22
`define ALU_REG_ADDR    23

`define ALU_REG_ZERO    30
`define ALU_REG_NONE    31

// specific bits
`define ALU_HST_XM       0
`define ALU_HST_SB       1
`define ALU_HST_SR       2
`define ALU_HST_MP       3

/*
 * 
 * instruction types
 *
 */


`define INSTR_TYPE_NOP          0
`define INSTR_TYPE_ALU          1
`define INSTR_TYPE_SET_MODE     2
`define INSTR_TYPE_JUMP         3
`define INSTR_TYPE_RTN          4
`define INSTR_TYPE_LOAD_LENGTH  5
`define INSTR_TYPE_LOAD         6
`define INSTR_TYPE_MEM_READ     7
`define INSTR_TYPE_MEM_WRITE    8
`define INSTR_TYPE_CONFIG       9
`define INSTR_TYPE_RESET       10


`define INSTR_TYPE_NONE         15

`endif