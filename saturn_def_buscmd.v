
/**************************************************************************************************
 *
 * Bus commands
 * 
 *
 *
 */

`ifndef _BUSCMD
`define _BUSCMD

`define BUSCMD_NOP			4'h0
`define BUSCMD_ID			4'h1
`define BUSCMD_PC_READ		4'h2
`define BUSCMD_DP_READ		4'h3
`define BUSCMD_PC_WRITE		4'h4	
`define BUSCMD_DP_WRITE		4'h5
`define BUSCMD_LOAD_PC		4'h6
`define BUSCMD_LOAD_DP		4'h7
`define BUSCMD_CONFIGURE	4'h8
`define BUSCMD_UNCONFIGURE	4'h9
`define BUSCMD_RESET		4'hF

`endif
