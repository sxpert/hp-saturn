`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START         12'h000      //  X
`define DEC_0X            12'h001      //  0X
`define DEC_1X            12'h100      //  1X
`define DEC_13X           12'h130      //  13X
`define DEC_14X           12'h140      //  14X
`define DEC_15X           12'h150      //  15X
`define DEC_15X_FIELD     12'h151      //  15XX
`define DEC_MEMAXX        12'h152      //  1[45]x[y]
`define DEC_MEMAXX_END    12'h153      
`define DEC_D0_EQ_5N      12'h1B0      //  1B
`define DEC_D0_EQ_LOOP    12'h1B1      //  1Bxxxxx (exec)
`define DEC_D1_EQ_4N      12'h1E0      //  1E
`define DEC_D1_EQ_5N      12'h1F0      //  1F
`define DEC_D1_EQ_LOOP    12'h1F1      //  1[EF]xxxxx (exec)
`define DEC_P_EQ_N        12'h200      //  2n
`define DEC_LC_LEN        12'h300      //  3n...
`define DEC_LC            12'h301      //  3n[x]
`define DEC_GOTO          12'h600      //  6
`define DEC_GOTO_LOOP     12'h601      //  6[x] -> exec
`define DEC_GOSUB         12'h700      //  7
`define DEC_GOSUB_LOOP    12'h701      //  7[x] -> exec
`define DEC_8X            12'h800      //  8X
`define DEC_80X           12'h801      //  80X
`define DEC_CONFIG        12'h805      //  805
`define DEC_RESET         12'h80A      //  80A
`define DEC_C_EQ_P_N      12'h80C      //  80Cm
`define DEC_82X_CLRHST    12'h820      //  82X
`define DEC_ST_EQ_0_N     12'h840      //  84n
`define DEC_ST_EQ_1_N     12'h850      //  85n
`define DEC_8AX           12'h8A0      //  8Ax
`define DEC_GOVLNG        12'h8D0      //  8D
`define DEC_GOVLNG_LOOP   12'h8D1      //  8D[x]
`define DEC_GOVLNG_EXEC   12'h8D2      //  8Dxxxxx -> exec
`define DEC_GOSBVL        12'h8F0      //  8F
`define DEC_GOSBVL_LOOP   12'h8F1      //  8F[x]
`define DEC_GOSBVL_EXEC   12'h8F2      //  8Fxxxxx -> exec
`define DEC_AX            12'hA00      //  Ax
`define DEC_AaX_EXEC      12'hA01      //  Aax
`define DEC_AbX_EXEC      12'hA02      //  Abx
`define DEC_BX            12'hB00      //  Bx
`define DEC_CX            12'hC00      //  Cx 
`define DEC_DX            12'hD00      //  Dx
`define DEC_FX            12'hF00      //  Fx
`define DEC_TEST_GO       12'hFFF      //  GOYES / RTNYES

`endif