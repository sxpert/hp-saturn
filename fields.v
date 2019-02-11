`ifndef _FIELDS
`define _FIELDS

`define T_SET            0
`define T_TEST           1

`define T_DIR_OUT	     0
`define T_DIR_IN		 1

`define T_PTR_0		     0
`define T_PTR_1		     1

`define T_REG_A		     0
`define T_REG_C		     1

`define T_FTYPE_FIELD    0
`define T_TTYPE_LEN      1

`define T_TABLE_A        0
`define T_TABLE_B        1
`define T_TABLE_F        2
`define T_TABLE_Z        3 // unused

`define T_FIELD_P	     0
`define T_FIELD_WP	     1
`define T_FIELD_XS	     2
`define T_FIELD_X	     3
`define T_FIELD_S	     4
`define T_FIELD_M	     5
`define T_FIELD_B	     6
`define T_FIELD_W	     7
`define T_FIELD_A	    15

`define ALU_OP_ZERO      0
`define ALU_OP_COPY      1
`define ALU_OP_EXCH      2
`define ALU_OP_SHL       3
`define ALU_OP_SHR       4
`define ALU_OP_2CMPL     5
`define ALU_OP_1CMPL     6
`define ALU_OP_INC       8
`define ALU_OP_DEC       9
`define ALU_OP_ADD      10
`define ALU_OP_SUB      11
`define ALU_OP_ADD_CST  12
`define ALU_OP_SUB_CST  13
`define ALU_OP_TEST_EQ  14
`define ALU_OP_TEST_NEQ 15


`define ALU_REG_A        0
`define ALU_REG_B        1
`define ALU_REG_C        2
`define ALU_REG_D        3
`define ALU_REG_D0       4
`define ALU_REG_D1       5
// 6
// 7
`define ALU_REG_R0       8
`define ALU_REG_R1       9
`define ALU_REG_R2      10
`define ALU_REG_R3      11
`define ALU_REG_R4      12
`define ALU_REG_CST     13
`define ALU_REG_M       14
`define ALU_REG_0       15

`endif