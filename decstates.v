`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START           12'h000         //  X
`define DEC_0X              12'h001         //  0X
`define DEC_1X              12'h100         //  1X
`define DEC_13X             12'h130         //  13X
`define DEC_14X             12'h140         //  14X
`define DEC_15X             12'h150         //  15X
`define DEC_15X_FIELD       12'h151         //  15XX
`define DEC_MEMAXX          12'h152         //  1[45]x[y]
`define DEC_MEMAXX_END      12'h153      
`define DEC_PTR_MATH        12'h160         //  1[678C]n   D[01]=D[01][+-] (n+1)
`define DEC_D0_EQ_2N        12'h190         //  19
`define DEC_D0_EQ_4N        12'h1A0         //  1A
`define DEC_D0_EQ_5N        12'h1B0         //  1B
`define DEC_D0_EQ_LOOP      12'h1B1         //  1Bxxxxx (exec)
`define DEC_D1_EQ_2N        12'h1D0         //  1D
`define DEC_D1_EQ_4N        12'h1E0         //  1E
`define DEC_D1_EQ_5N        12'h1F0         //  1F
`define DEC_D1_EQ_LOOP      12'h1F1         //  1[EF]xxxxx (exec)
`define DEC_P_EQ_N          12'h200         //  2n
`define DEC_LC              12'h300         //  3n[x]
`define DEC_GOTO            12'h600         //  6
`define DEC_GOTO_LOOP       12'h601         //  6[x] -> exec
`define DEC_GOSUB           12'h700         //  7
`define DEC_GOSUB_LOOP      12'h701         //  7[x] -> exec
`define DEC_8X              12'h800         //  8X
`define DEC_80X             12'h801         //  80X
`define DEC_808X            12'h808         //  808X
`define DEC_AC_BIT_SET_TEST 12'h809         //  808[4-B]x
`define DEC_C_EQ_P_N        12'h80C         //  80Cn       C=P n
`define DEC_P_EQ_C_N        12'h80D         //  80Dn       P=C n
`define DEC_82X_CLRHST      12'h820         //  82X
`define DEC_ST_EQ_0_N       12'h840         //  84n        ST=0    n
`define DEC_ST_EQ_1_N       12'h850         //  85n        ST=1    n
`define DEC_TEST_ST_EQ_0_N  12'h860         // 86n      ?ST=0   n
`define DEC_TEST_ST_EQ_1_N  12'h870         // 87n      ?ST=1   n
`define DEC_TEST_P_NEQ_N    12'h880         // 88n      ?P#     n
`define DEC_TEST_P_EQ_N     12'h890         // 89n      ?P=     n
`define DEC_8AX             12'h8A0         //  8Ax
`define DEC_GOVLNG          12'h8D0         //  8D
`define DEC_GOVLNG_LOOP     12'h8D1         //  8D[x]
`define DEC_GOVLNG_EXEC     12'h8D2         //  8Dxxxxx -> exec
`define DEC_GOSBVL          12'h8F0         //  8F
`define DEC_GOSBVL_LOOP     12'h8F1         //  8F[x]
`define DEC_GOSBVL_EXEC     12'h8F2         //  8Fxxxxx -> exec
`define DEC_Axx_EXEC        12'hA00         //  A[ab]x
`define DEC_Bxx_EXEC        12'hB00         //  B[ab]x
`define DEC_CX              12'hC00         //  Cx 
`define DEC_DX              12'hD00         //  Dx
`define DEC_FX              12'hF00         //  Fx
`define DEC_TEST_GO         12'hFF0         //  GOYES / RTNYES  nibble 1
`define DEC_TEST_GO_1       12'hFF1         //  GOYES / RTNYES  nibble 2
`define DEC_ALU_INIT        12'hFF8         //  Start ALU operations
`define DEC_ALU_CONT        12'hFF9         //  Subsequent ALU operations
`define DEC_ab_FIELDS       12'hFFE         //  a and b fields table
`define DEC_f_FIELDS        12'hFFF         //  f fields table

`endif