
/**************************************************************************************************
 *
 * Bus commands
 * 
 *
 *
 */

`ifndef _BUS_COMMANDS
`define _BUS_COMMANDS

`define BUSCMD_NOP			0
`define BUSCMD_ID			1
`define BUSCMD_PC_READ		2
`define BUSCMD_DP_READ		3
`define BUSCMD_PC_WRITE		4	
`define BUSCMD_DP_WRITE		5
`define BUSCMD_LOAD_PC		6
`define BUSCMD_LOAD_DP		7
`define BUSCMD_CONFIGURE	8
`define BUSCMD_UNCONFIGURE	9
`define BUSCMD_RESET		15

`endif
