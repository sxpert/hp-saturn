`ifndef _DECSTATES
`define _DECSTATES


`define DEC_START            0      //  X
`define DEC_P_EQ_N           1      //  2n
`define DEC_GOTO             2      //  6
`define DEC_GOTO_LOOP        3      //  6[x]
`define DEC_GOTO_EXEC        4      //  6xxx -> exec
`define DEC_8X               5      //  8X
`define DEC_80X              6      //  80X
`define DEC_C_EQ_P_N         7      //  80Cm
`define DEC_ST_EQ_0_N        8      //  84n
`define DEC_ST_EQ_1_N        9      //  85n
`define DEC_GOVLNG          10      //  8D
`define DEC_GOVLNG_LOOP     11      //  8D[x]
`define DEC_GOVLNG_EXEC     12      //  8Dxxxxx -> exec
`define DEC_GOSBVL          13      //  8F
`define DEC_GOSBVL_LOOP     14      //  8F[x]
`define DEC_GOSBVL_EXEC     15      //  8Fxxxxx -> exec

`endif