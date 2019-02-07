`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START            0      //  X
`define DEC_0X               1      //  0X
`define DEC_RTNCC            2      //  03
`define DEC_SETHEX           3      //  04
`define DEC_SETDEC           4      //  05
`define DEC_P_EQ_N           5      //  2n
`define DEC_GOTO             6      //  6
`define DEC_GOTO_LOOP        7      //  6[x]
`define DEC_GOTO_EXEC        8      //  6xxx -> exec
`define DEC_8X               9      //  8X
`define DEC_80X             10      //  80X
`define DEC_RESET           11      //  80A
`define DEC_C_EQ_P_N        12      //  80Cm
`define DEC_82X_CLRHST      13      //  82X
`define DEC_ST_EQ_0_N       14      //  84n
`define DEC_ST_EQ_1_N       15      //  85n
`define DEC_GOVLNG          16      //  8D
`define DEC_GOVLNG_LOOP     17      //  8D[x]
`define DEC_GOVLNG_EXEC     18      //  8Dxxxxx -> exec
`define DEC_GOSBVL          19      //  8F
`define DEC_GOSBVL_LOOP     20      //  8F[x]
`define DEC_GOSBVL_EXEC     21      //  8Fxxxxx -> exec

`endif