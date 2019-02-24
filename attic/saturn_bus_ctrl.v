/*
    (c) Raphaël Jacquot 2019
    
    This file is part of hp_saturn.

    hp_saturn is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    any later version.

    hp_saturn is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.

 */


`include "def-clocks.v"
`include "def-buscmd.v"

`ifndef _SATURN_BUS_CTRL
`define _SATURN_BUS_CTRL

`default_nettype none

/*
 * enable more debug messages
 */ 
`ifdef SIM
`define DEBUG_CTRL
`endif

module saturn_bus_ctrl (
  i_clk,
  i_reset,
  i_phases,
  i_cycle_ctr,
  i_stalled,
  i_alu_busy,

  o_stall_alu,
  o_bus_done,

  // bus i/o
  o_bus_reset,
  i_bus_data,
  o_bus_data,
  o_bus_strobe,
  o_bus_cmd_data,

  // interface to the rest of the machine
  i_alu_pc,
  i_address,
  i_data_nibl,
  o_data_ptr,
  i_cmd_load_pc,
  i_cmd_load_dp,
  i_read_pc,
  i_cmd_dp_read,
  i_cmd_dp_write,
  i_cmd_reset,
  i_cmd_config,
  i_mem_xfr,
  i_xfr_out,
  i_xfr_cnt,
  i_nibble,
  o_nibble
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [3:0]  i_phases;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_stalled;
input  wire [0:0]  i_alu_busy;

output reg  [0:0]  o_stall_alu;
output reg  [0:0]  o_bus_done;

output reg  [0:0]  o_bus_reset;
input  wire [3:0]  i_bus_data;
output reg  [3:0]  o_bus_data;
output wire [0:0]  o_bus_strobe;
output reg  [0:0]  o_bus_cmd_data;

input  wire [19:0] i_alu_pc;
input  wire [19:0] i_address;
input  wire [3:0]  i_data_nibl;
output reg  [3:0]  o_data_ptr;
input  wire [0:0]  i_cmd_load_pc;
input  wire [0:0]  i_cmd_load_dp;
input  wire [0:0]  i_read_pc;
input  wire [0:0]  i_cmd_dp_read;
input  wire [0:0]  i_cmd_dp_write;
input  wire [0:0]  i_cmd_reset;
input  wire [0:0]  i_cmd_config;
input  wire [0:0]  i_mem_xfr;
input  wire [0:0]  i_xfr_out;
input  wire [3:0]  i_xfr_cnt;

input  wire [3:0]  i_nibble;
output reg  [3:0]  o_nibble;

/******************************************************************************
 *
 * clocking enables
 *
 ****************************************************************************/

// bus startup
reg  [0:0] bus_out_of_reset;
wire [0:0] bus_reset_event;
wire [0:0] reset_bus;
wire [0:0] bus_start;
wire [0:0] bus_active;
reg  [0:0] strobe_on;
assign bus_reset_event = !i_reset && !i_stalled && bus_out_of_reset;
assign reset_bus       = bus_reset_event && phase_0 && !strobe_on;
assign bus_start       = bus_reset_event && phase_1 &&  strobe_on;
assign bus_active      = !i_reset && !i_stalled && !bus_out_of_reset;
assign o_bus_strobe    = phase_1 && strobe_on;

// events phases

wire [0:0] phase_0;
wire [0:0] phase_1;
wire [0:0] phase_2;
wire [0:0] phase_3;

assign phase_0 = i_phases[0];
assign phase_1 = i_phases[1];
assign phase_2 = i_phases[2];
assign phase_3 = i_phases[3];

reg [1:0] phase;

always @(*) begin
  phase = 2'd0;
  case (1'b1)
  phase_0: phase = 2'd0;
  phase_1: phase = 2'd1;
  phase_2: phase = 2'd2;
  phase_3: phase = 2'd3;
  default: phase = 2'd0;
  endcase
end

/******************************************************************************
 *
 * THE EVIL STATE MACHINE !
 *
 *****************************************************************************/

// actual commands

/* the last command sent to the bus
 * initialized to 0, BUSCMD_NOP
 */
reg [3:0] last_cmd;

/* tests on last_cmd */

wire [0:0] LC_pc_read;
wire [0:0] LC_pc_write;
wire [0:0] LC_dp_read;
wire [0:0] LC_dp_write;
wire [0:0] LC_load_pc;
wire [0:0] LC_load_dp;

assign LC_pc_read  = (last_cmd == `BUSCMD_PC_READ);
assign LC_pc_write = (last_cmd == `BUSCMD_PC_WRITE);
assign LC_dp_read  = (last_cmd == `BUSCMD_DP_READ);
assign LC_dp_write = (last_cmd == `BUSCMD_DP_WRITE);
assign LC_load_pc  = (last_cmd == `BUSCMD_LOAD_PC);
assign LC_load_dp  = (last_cmd == `BUSCMD_LOAD_DP);

/* current pointer
 * 0: PC
 * 1: DP
 */
reg [0:0] current_pointer;

/*
 * Events naming conventions
 *
 * bus commands (use the "cmd" prefix) :
 *
 * cmd_[foo]_F   : flag to indicate cmd_[foo] was done
 * cmd_[foo]_TST : test if cmd_[foo] needs to be done
 * cmd_[foo]_x   : whatever needs to be done for cmd_[foo], step x
 * cmd_[foo]_STR : when there is a need for a strobe on phase 0
 * cmd_[foo]_STx : if cmd_[foo] needs to stall the ALU and core, step x
 * cmd_[foo]_USx : if cmd_[foo] neesd to un-stall the ALU and core, step x
 * cmd_[foo]_C   : when flags for the execution of cmd_[foo] need to be cleaned
 *
 * bus actions (use the "do" prefix) :
 *
 * do_[foo]_TST  : test if do_[foo] can be done
 * do_[foo]_x    : whatever needs to be done for do_[foo], step x
 * do_[foo]_STR  : when there is a need for a strobe on phase 0
 *
 * note: strobe removal is automatic on phase 1
 *
 */

/*
 * read from the PC pointer
 */

// sending readpc
reg  [0:0] cmd_PC_READ_F;

wire [0:0] cmd_PC_READ_TST;
wire [0:0] cmd_PC_READ_0;
wire [0:0] cmd_PC_READ_STR;

assign cmd_PC_READ_TST = !cmd_PC_READ_F &&
                         (cmd_DP_WRITE_F1 || cmd_CONFIGURE_F1 || cmd_RESET_sr[3]); 
assign cmd_PC_READ_0   = phase_0 && cmd_PC_READ_TST; // sets cmd_PC_READ_F
assign cmd_PC_READ_STR = cmd_PC_READ_0;

// doing actual reads
wire [0:0] do_READ_PC_TST;
wire [0:0] do_READ_PC_0;
wire [0:0] do_READ_PC_STR;

assign do_READ_PC_TST = !i_alu_busy && LC_pc_read;
assign do_READ_PC_0   = phase_1 && do_READ_PC_TST;
assign do_READ_PC_STR = do_READ_PC_TST;

/*
 * common to both reading and writing to the dp pointer
 */

wire [0:0] xfr_done;
assign xfr_done = (o_data_ptr == (i_xfr_cnt + 1));

/*
 * read from the DP pointer
 */

reg  [0:0] cmd_DP_READ_F;


wire [0:0] do_read_dp_en;
wire [0:0] do_read_dp_str;
reg  [0:0] do_read_dp_s;
wire [0:0] do_read_dp;
wire [0:0] do_read_dp_US;
wire [0:0] do_read_dp_C;
wire [0:0] do_read_dp_US2;
assign do_read_dp_en  = i_cmd_dp_read && LC_dp_read;
assign do_read_dp_str = phase_0 && do_read_dp_en;
assign do_read_dp     = phase_1 && do_read_dp_en;
assign do_read_dp_US  = phase_3 && do_read_dp_en && o_stall_alu;
assign do_read_dp_C   = phase_0 && !i_cmd_dp_read && LC_dp_read && do_read_dp_s;
assign do_read_dp_US2 = phase_3 && do_read_dp_s && cmd_PC_READ_F;

/*
 * write to the DP pointer
 */

// setup the DP pointer
reg  [0:0] cmd_DP_WRITE_F0;
reg  [0:0] cmd_DP_WRITE_F1;
wire [0:0] cmd_DP_WRITE_TST;
wire [0:0] cmd_DP_WRITE_0;
wire [0:0] cmd_DP_WRITE_1;
wire [0:0] cmd_DP_WRITE_STR;
wire [0:0] cmd_DP_WRITE_US0;
wire [0:0] cmd_DP_WRITE_US1;
wire [0:0] cmd_DP_WRITE_C;
assign cmd_DP_WRITE_TST = i_cmd_dp_write && LC_dp_read && !cmd_DP_WRITE_F0;
assign cmd_DP_WRITE_0   = phase_0 && cmd_DP_WRITE_TST; // sets cmd_DP_WRITE_F0
assign cmd_DP_WRITE_STR = cmd_DP_WRITE_0;
assign cmd_DP_WRITE_US0 = phase_2 && cmd_DP_WRITE_F0 && !cmd_DP_WRITE_F1 && o_stall_alu;
// after all nibbles were sent
assign cmd_DP_WRITE_1   = phase_3 && xfr_done && cmd_DP_WRITE_F0 && !cmd_DP_WRITE_F1; // sets cmd_DP_WRITE_F1
assign cmd_DP_WRITE_US1 = phase_2 && cmd_DP_WRITE_F1;
assign cmd_DP_WRITE_C   = phase_3 && cmd_DP_WRITE_F1; 

// do actual writes
wire [0:0] do_WRITE_DP_TST;
wire [0:0] do_WRITE_DP_0;
wire [0:0] do_WRITE_DP_STR;
assign do_WRITE_DP_TST = !o_stall_alu && i_cmd_dp_write && LC_dp_write && !xfr_done;
assign do_WRITE_DP_STR = phase_0 && do_WRITE_DP_TST;
assign do_WRITE_DP_0   = phase_0 && do_WRITE_DP_TST;

/*
 * LOAD_PC : load a new PC in
 */

reg  [0:0] cmd_LOAD_PC_F;

wire [0:0] cmd_LOAD_PC_TST;
wire [0:0] cmd_LOAD_PC_0;
wire [0:0] cmd_LOAD_PC_STR;
wire [0:0] cmd_LOAD_PC_C;

assign cmd_LOAD_PC_TST = i_cmd_load_pc;
assign cmd_LOAD_PC_0   = phase_0 && cmd_LOAD_PC_TST; // sets cmd_LOAD_PC_F
assign cmd_LOAD_PC_STR = cmd_LOAD_PC_TST;
assign cmd_LOAD_PC_C   = phase_3 && do_auto_PC_READ_TST;

/*
 * auto switch to PC_READ after LOAD_PC
 */
wire [0:0] do_auto_PC_READ_TST;
wire [0:0] do_auto_PC_READ_0;
wire [0:0] do_auto_PC_READ_US0;

assign do_auto_PC_READ_TST = cmd_LOAD_PC_F && addr_loop_done;
assign do_auto_PC_READ_0   = phase_1 && do_auto_PC_READ_TST;
assign do_auto_PC_READ_US0 = phase_3 && o_stall_alu && do_auto_PC_READ_TST && cmd_LOAD_PC_F;

/* 
 * LOAD_DP : load a new DP in
 */

reg  [0:0] cmd_LOAD_DP_F;

wire [0:0] cmd_LOAD_DP_TST;
wire [0:0] cmd_LOAD_DP_0;
wire [0:0] cmd_LOAD_DP_STR;
wire [0:0] cmd_LOAD_DP_C;

assign cmd_LOAD_DP_TST = i_cmd_load_dp && !cmd_LOAD_DP_F;
assign cmd_LOAD_DP_0   = phase_0 && cmd_LOAD_DP_TST; // sets cmd_LOAD_DP_F
assign cmd_LOAD_DP_STR = cmd_LOAD_DP_TST;
assign cmd_LOAD_DP_C   = phase_3 && do_auto_DP_READ_TST;

/*
 * auto switch to PC_READ after LOAD_PC
 */
wire [0:0] do_auto_DP_READ_TST;
wire [0:0] do_auto_DP_READ_0;
wire [0:0] do_auto_DP_READ_US0;

assign do_auto_DP_READ_TST = cmd_LOAD_DP_F && addr_loop_done;
assign do_auto_DP_READ_0   = phase_1 && do_auto_DP_READ_TST;
// does nothing ?
assign do_auto_DP_READ_US0 = phase_3 && o_stall_alu && do_auto_DP_READ_TST && cmd_LOAD_DP_F && !(cmd_DP_WRITE_F0); // || cmd_DP_READ_F);

/*
 * CONFIGURE : execute a configure 
 */

reg  [0:0] cmd_CONFIGURE_F0;
reg  [0:0] cmd_CONFIGURE_F1;

wire [0:0] cmd_CONFIGURE_TST;
wire [0:0] cmd_CONFIGURE_0;
wire [0:0] cmd_CONFIGURE_STR;
wire [0:0] cmd_CONFIGURE_1;
wire [0:0] cmd_CONFIGURE_US0;
wire [0:0] cmd_CONFIGURE_C;

assign cmd_CONFIGURE_TST = i_cmd_config && !cmd_CONFIGURE_F0;
assign cmd_CONFIGURE_0   = phase_0 && cmd_CONFIGURE_TST; // sets cmd_CONFIGURE_F0
assign cmd_CONFIGURE_STR = cmd_CONFIGURE_0;
assign cmd_CONFIGURE_1   = phase_3 && cmd_CONFIGURE_F0 && is_loop_finished;
assign cmd_CONFIGURE_US0 = phase_1 && cmd_CONFIGURE_F1 && cmd_PC_READ_F;
assign cmd_CONFIGURE_C   = phase_3 && cmd_CONFIGURE_F1 && cmd_PC_READ_F;

/*
 * RESETexecute a bus reset
 */

// reg  [0:0] cmd_RESET_F;

// wire [0:0] cmd_RESET_0;
// wire [0:0] cmd_RESET_STR;
// wire [0:0] cmd_RESET_ST0;
// wire [0:0] cmd_RESET_US0;
// wire [0:0] cmd_RESET_C;

// assign cmd_RESET_0   = phase_0 && !i_stalled && i_cmd_reset && !cmd_RESET_F; // && !cmd_PC_READ_F; // sets cmd_RESET_F
// assign cmd_RESET_STR = cmd_RESET_0;
// assign cmd_RESET_ST0 = phase_3 && i_cmd_reset && !cmd_RESET_F && !cmd_PC_READ_F;
// assign cmd_RESET_US0 = phase_2 && i_cmd_reset && cmd_RESET_F && cmd_PC_READ_F;
// assign cmd_RESET_C   = phase_0 && !i_stalled && i_cmd_reset && cmd_RESET_F && cmd_PC_READ_F;

initial cmd_RESET_sr = 9'b0;
reg  [8:0] cmd_RESET_sr;
wire [0:0] cmd_RESET_busy;
wire [0:0] cmd_RESET_start;
assign cmd_RESET_busy = | cmd_RESET_sr;
assign cmd_RESET_start = !i_stalled && !bus_busy && phase_3 && i_cmd_reset;

wire [0:0] bus_busy;
assign bus_busy = cmd_RESET_busy;

// automatic stuff

wire [0:0] do_read;
assign do_read = do_READ_PC_0 || do_read_dp;

/*
 * bus strobe management
 */
wire [0:0] do_cmd_strobe;
wire [0:0] do_read_strobe;
wire [0:0] do_write_strobe;
wire [0:0] do_strobe;
wire [0:0] do_remove_strobe;
assign do_cmd_strobe    = cmd_PC_READ_STR || cmd_DP_WRITE_STR || cmd_LOAD_PC_STR || cmd_LOAD_DP_STR || cmd_CONFIGURE_STR || cmd_RESET_sr[0];
assign do_read_strobe   = do_READ_PC_STR; // || do_READ_DP_STR;
assign do_write_strobe  = do_WRITE_DP_STR;
assign do_strobe        = phase_0 && 
                          (do_cmd_strobe || do_run_addr_loop || do_read_strobe || do_write_strobe);
assign do_remove_strobe = phase_1 && strobe_on;

wire [0:0] do_read_stalled_by_alu;
assign do_read_stalled_by_alu = phase_1 && i_alu_busy && LC_pc_read;

wire [0:0] do_unstall;
assign do_unstall = o_stall_alu &&
                    (do_read_dp_US2 || 
                     cmd_DP_WRITE_1 ||
                     cmd_DP_WRITE_US0 || 
                     cmd_DP_WRITE_US1 ||
                     do_auto_PC_READ_US0 ||
                     cmd_CONFIGURE_US0 || 
                     cmd_RESET_sr[8]);

wire [0:0] do_load_clean;
wire [0:0] do_clean;
assign do_load_clean = cmd_LOAD_PC_C || cmd_LOAD_DP_C;
assign do_clean = do_read_dp_US2 || cmd_DP_WRITE_C || cmd_CONFIGURE_C ;

reg  [0:0] addr_loop_done;
reg  [0:0] init_addr_loop;
reg  [0:0] run_addr_loop;
wire [0:0] do_init_addr_loop;
wire [0:0] do_run_addr_loop;
wire [0:0] will_loop_finish;
wire [0:0] is_loop_finished;
wire [0:0] do_reset_loop_counter;
assign do_init_addr_loop = phase_0 && 
                           (init_addr_loop || 
                            cmd_LOAD_PC_TST || 
                            cmd_LOAD_DP_TST || 
                            cmd_CONFIGURE_0);
assign do_run_addr_loop = phase_0 && run_addr_loop && !is_loop_finished;
assign will_loop_finish = o_data_ptr == 4;
assign is_loop_finished = o_data_ptr == 5;
assign do_reset_loop_counter = phase_3 && is_loop_finished;

/******************************************************************************
 *
 * the controller itself
 *
 ****************************************************************************/

initial begin

  `ifdef SIM

  // $monitor ("BUS_CTRL %1d: [%d] i_stalled %b | i_cmd_reset %b | bus_busy %b | cmd_RESET_sr %b", 
  //           phase, i_cycle_ctr, i_stalled, i_cmd_reset, bus_busy, cmd_RESET_sr);
  `endif
end

always @(posedge i_clk) begin
  if (i_reset) begin
    last_cmd          <= 0;
    o_stall_alu       <= 1;
    o_bus_reset       <= 1;
    strobe_on         <= 0;
    o_bus_cmd_data    <= 1; // 1 is the default level
    bus_out_of_reset  <= 1;
    o_data_ptr        <= 0;
    // local states

    // address loop
    init_addr_loop    <= 0;
    run_addr_loop     <= 0;
    addr_loop_done    <= 0;

    // read and write loops
    o_data_ptr        <= 0;

    cmd_PC_READ_F     <= 0;
    cmd_DP_READ_F     <= 0;
    cmd_DP_WRITE_F0   <= 0;
    cmd_DP_WRITE_F1   <= 0;
    cmd_LOAD_PC_F     <= 0;
    cmd_LOAD_DP_F     <= 0;
    cmd_CONFIGURE_F0  <= 0;
    cmd_CONFIGURE_F1  <= 0;
    // cmd_RESET_F       <= 0;
  end

  if (reset_bus) begin
    $display("reset bus");
    strobe_on <= 1;
  end

  if (bus_start) begin
    $display("bus start");
    strobe_on        <= 0;
    o_bus_reset      <= 0;
    bus_out_of_reset <= 0;
    o_stall_alu      <= 0;
  end

  /*
   * PC_READ
   */ 

  if (cmd_PC_READ_0) begin
    $display("BUS_CTRL %1d: [%d] PC_READ", phase, i_cycle_ctr);
    cmd_PC_READ_F    <= 1;        
    last_cmd         <= `BUSCMD_PC_READ;
    o_bus_data       <= `BUSCMD_PC_READ;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
  end

  /*
   * DP_WRITE
   */ 

  if (cmd_DP_WRITE_0) begin
    $display("BUS_CTRL %1d: [%d] DP_WRITE (%0d nibble to write - ctr %0d)", phase, i_cycle_ctr, i_xfr_cnt + 1, o_data_ptr);
    cmd_DP_WRITE_F0 <= 1;   
    o_data_ptr      <= 0;     
    last_cmd        <= `BUSCMD_DP_WRITE;
    o_bus_data      <= `BUSCMD_DP_WRITE;
    o_bus_cmd_data  <= 0;
    // o_stall_alu     <= 1;
  end

  if (cmd_DP_WRITE_1) begin
    $display("BUS_CTRL %1d: [%d] cmd_DP_WRITE_1 (sets cmd_DP_WRITE_F1)", phase, i_cycle_ctr);
    cmd_DP_WRITE_F1 <= 1;
    // o_stall_alu     <= 1;
  end

  if (cmd_DP_WRITE_US0) begin
    $display("BUS_CTRL %1d: [%d] cmd_DP_WRITE_US0", phase, i_cycle_ctr);
  end

  if (cmd_DP_WRITE_US1) begin
    $display("BUS_CTRL %1d: [%d] cmd_DP_WRITE_US1 (signal done)", phase, i_cycle_ctr);
    o_bus_done <= 1;
  end

  if (cmd_DP_WRITE_C) begin
    $display("BUS_CTRL %1d: [%d] cmd_DP_WRITE_C", phase, i_cycle_ctr);
    o_bus_done <= 0;
  end

  /*
   *
   * LOAD_PC 
   *
   */ 

  if (cmd_LOAD_PC_0) begin
    $display("BUS_CTRL %1d: [%d] LOAD_PC [%5h]", phase, i_cycle_ctr, i_address);
    cmd_LOAD_PC_F    <= 1;
    last_cmd         <= `BUSCMD_LOAD_PC;
    o_bus_data       <= `BUSCMD_LOAD_PC;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
    init_addr_loop   <= 1;
  end

  /* automatic PC_READ after LOAD_PC */

  if (do_auto_PC_READ_0) begin
    $display("BUS_CTRL %1d: [%d] auto PC_READ", phase, i_cycle_ctr);
    last_cmd <= `BUSCMD_PC_READ;
  end

`ifdef DEBUG_CTRL
  if (do_auto_PC_READ_US0) begin
    $display("BUS_CTRL %1d: [%d] auto PC_READ - unstall", phase, i_cycle_ctr);
  end
`endif

  /*
   *
   * LOAD_DP
   *
   */

  if (cmd_LOAD_DP_0) begin
    $display("BUS_CTRL %1d: [%d] LOAD_DP [%5h]", phase, i_cycle_ctr, i_address);
    cmd_LOAD_DP_F    <= 1;
    last_cmd         <= `BUSCMD_LOAD_DP;
    o_bus_data       <= `BUSCMD_LOAD_DP;
    o_bus_cmd_data   <= 0;
    // o_stall_alu      <= 1;
    init_addr_loop   <= 1;
  end

  /* automatic DP_READ after LOAD_DP */

  if (do_auto_DP_READ_0) begin
    $display("BUS_CTRL %1d: [%d] auto DP_READ (%0d nibble to read - ctr %0d)", phase, i_cycle_ctr, i_xfr_cnt + 1, o_data_ptr);
    cmd_DP_READ_F <= 1;
    last_cmd      <= `BUSCMD_DP_READ;
  end

/******************************************************************************
 *
 * CONFIGURE command
 *
 *****************************************************************************/

  if (cmd_CONFIGURE_0) begin
    $display("BUS_CTRL %1d: [%d] CONFIGURE [%5h]", phase, i_cycle_ctr, i_address);
    cmd_CONFIGURE_F0 <= 1;
    last_cmd         <= `BUSCMD_CONFIGURE;
    o_bus_data       <= `BUSCMD_CONFIGURE;
    o_bus_cmd_data   <= 0;
    init_addr_loop   <= 1;
  end

  if (cmd_CONFIGURE_1) begin
    $display("BUS_CTRL %1d: [%d] set cmd_CONFIGURE_F1", phase, i_cycle_ctr);
    cmd_CONFIGURE_F1  <= 1;
  end

  if (cmd_CONFIGURE_US0) begin
    $display("BUS_CTRL %1d: [%d] cmd_CONFIGURE_US0 (signal done)", phase, i_cycle_ctr);
    o_bus_done <= 1;
    o_stall_alu <= 0;
  end

  if (cmd_CONFIGURE_C) begin
    $display("BUS_CTRL %1d: [%d] cmd_CONFIGURE_C", phase, i_cycle_ctr);
    o_bus_done <= 0;
  end

/******************************************************************************
 *
 * reset command
 *
 *****************************************************************************/

  // if (cmd_RESET_ST0) begin
  //   // $display("BUS_CTRL %1d: [%d] reset stall", phase, i_cycle_ctr);
  //   o_stall_alu      <= 1;
  // end

  // $display("phase_0 %b | !i_stalled %b | i_cmd_reset %b | !cmd_RESET_F %b | ! cmd_PC_READ_F %b",
  //          phase_0, !i_stalled, i_cmd_reset, !cmd_RESET_F, !cmd_PC_READ_F);
  if (cmd_RESET_start) begin
    $display("BUS_CTRL %1d: [%d] RESET start", phase, i_cycle_ctr);
    cmd_RESET_sr    <= 9'b1;
    last_cmd        <= `BUSCMD_RESET;
    o_bus_data      <= `BUSCMD_RESET;
    o_bus_cmd_data  <= 0;
    o_stall_alu     <= 1;
  end

  if (!i_stalled && cmd_RESET_busy) begin
    $display("BUS_CTRL %1d: [%d] stall %b RESET_sr %b shift left", phase, i_cycle_ctr, i_stalled, cmd_RESET_sr);
    cmd_RESET_sr <= {cmd_RESET_sr[7:0], 1'b0};
  end

  if (!i_stalled && cmd_RESET_sr[4]) begin
    $display("BUS_CTRL %1d: [%d] RESET_sr %b time for PC_READ", phase, i_cycle_ctr, cmd_RESET_sr);
  end

  if (!i_stalled && cmd_RESET_sr[7]) begin
    $display("BUS_CTRL %1d: [%d] RESET_sr %b unstall alu", phase, i_cycle_ctr, cmd_RESET_sr);
    o_stall_alu <= 0;
  end

  /****************************************************************************
   * 
   * Address loop handling
   *
   ***************************************************************************/

  if (do_init_addr_loop) begin
    // $display("BUS_CTRL %1d: [%d] init addr loop", phase, i_cycle_ctr);
    addr_loop_done    <= 0;
    o_data_ptr <= 0;
    run_addr_loop     <= 1;
    init_addr_loop    <= 0;
  end

  if (do_run_addr_loop) begin
    $write("BUS_CTRL %1d: [%d] ADDR(%0d)-> %h ", 
           phase, i_cycle_ctr, o_data_ptr,
           LC_load_pc?i_address[o_data_ptr*4+:4]:i_data_nibl);
    if (will_loop_finish) $write("done");
    $write("\n");

    if (LC_load_pc) o_bus_data <= i_address[o_data_ptr*4+:4];
    if (LC_load_dp) o_bus_data <= i_data_nibl;
    // clean up at the end of loop
    o_data_ptr     <= o_data_ptr + 1;
    run_addr_loop  <= !will_loop_finish;
    addr_loop_done <= will_loop_finish; 
  end

  if (do_reset_loop_counter) begin
    // $display("BUS_CTRL %1d: [%d] reset loop counter", phase, i_cycle_ctr);
    o_data_ptr <= 0;
  end




  if (do_unstall) begin
`ifdef DEBUG_CTRL
    $display("BUS_CTRL %1d: [%d] remove stall", phase, i_cycle_ctr);
`endif
    o_stall_alu <= 0;
  end

  if (do_load_clean) begin
    $display("BUS_CTRL %1d: [%d] cleanup after load", phase, i_cycle_ctr);
    cmd_LOAD_PC_F <= 0;
    cmd_LOAD_DP_F <= 0;
    o_data_ptr <= 0;
  end

  if (do_clean) begin
    $display("BUS_CTRL %1d: [%d] cleanup", phase, i_cycle_ctr);
    cmd_PC_READ_F    <= 0;
    cmd_DP_READ_F    <= 0;
    cmd_DP_WRITE_F0  <= 0;
    cmd_DP_WRITE_F1  <= 0;
    cmd_CONFIGURE_F0 <= 0;
    cmd_CONFIGURE_F1 <= 0;
    // cmd_RESET_F      <= 0;
  end

  /*
   *
   * bus actions
   *
   */

  if (do_strobe) begin
    // $display("_/");
    strobe_on <= 1;
  end

  if (do_read_dp) begin
    // $display("set do_read_dp_s");
    do_read_dp_s <= 1;
  end

  if (do_read) begin
    o_nibble <= i_bus_data;
    $display("BUS_CTRL %1d: [%d] READ %h", phase, i_cycle_ctr, i_bus_data);
  end

  if (do_WRITE_DP_0) begin
    $display("BUS_CTRL %1d: [%d] WRITE %h %0d/%0d (%0d to go)", phase, i_cycle_ctr, i_data_nibl, o_data_ptr, i_xfr_cnt, i_xfr_cnt - o_data_ptr);
    o_bus_data <= i_data_nibl;
    o_data_ptr <= o_data_ptr + 1;
  end

  if (!i_stalled && do_read_stalled_by_alu) begin
    $display("BUS_CTRL %1d: [%d] read stall (alu)", phase, i_cycle_ctr);
  end

  if (do_remove_strobe) begin
    // $display("\\_");
    strobe_on   <= 0;
    o_bus_cmd_data <= 1;
  end


end

endmodule

`endif