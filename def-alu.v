`ifndef _DEF_ALU
`define _DEF_ALU

// stuff (where should that go ?)
`define T_SET            0
`define T_TEST           1

`define T_DIR_OUT	     0
`define T_DIR_IN		 1

`define T_PTR_0		     0
`define T_PTR_1		     1

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
// arithmetic
`define ALU_OP_2CMPL     7
`define ALU_OP_1CMPL     8
`define ALU_OP_INC       9
`define ALU_OP_DEC      10
`define ALU_OP_ADD      11
`define ALU_OP_SUB      12
`define ALU_OP_ADD_CST  13
`define ALU_OP_SUB_CST  14
// tests
`define ALU_OP_TEST_EQ  15
`define ALU_OP_TEST_NEQ 16


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
`define ALU_REG_CST     13
`define ALU_REG_ST      14
`define ALU_REG_P       15
`define ALU_REG_M       16

`endif