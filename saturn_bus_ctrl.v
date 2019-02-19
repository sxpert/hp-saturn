`ifndef _SATURN_BUS_CTRL
`define _SATURN_BUS_CTRL

`include "def-clocks.v"
`include "def-buscmd.v"

module saturn_bus_ctrl (
  // basic stuff
  i_clk,
  i_reset,
  i_phase,
  i_cycle_ctr,
  i_en_bus_send,
  i_en_bus_recv,
  i_en_bus_ecmd,
  i_stalled,
  i_read_stall,

  o_stall_alu,

  // bus i/o
  o_bus_reset,
  i_bus_data,
  o_bus_data,
  o_bus_strobe,
  o_bus_cmd_data,

  // interface to the rest of the machine
  i_alu_pc,
  i_address,
  i_cmd_load_pc,
  i_cmd_load_dp,
  i_read_pc,
  i_cmd_dp_read,
  i_cmd_dp_write,
  i_cmd_reset,
  i_cmd_config,
  i_nibble,
  o_nibble
);

input  wire [0:0]  i_clk;
input  wire [0:0]  i_reset;
input  wire [1:0]  i_phase;
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_en_bus_send;
input  wire [0:0]  i_en_bus_recv;
input  wire [0:0]  i_en_bus_ecmd;
input  wire [0:0]  i_stalled;
input  wire [0:0]  i_read_stall;

output reg  [0:0]  o_stall_alu;

output reg  [0:0]  o_bus_reset;
input  wire [3:0]  i_bus_data;
output reg  [3:0]  o_bus_data;
output wire [0:0]  o_bus_strobe;
output reg  [0:0]  o_bus_cmd_data;

input  wire [19:0] i_alu_pc;
input  wire [19:0] i_address;
input  wire [0:0]  i_cmd_load_pc;
input  wire [0:0]  i_cmd_load_dp;
input  wire [0:0]  i_read_pc;
input  wire [0:0]  i_cmd_dp_read;
input  wire [0:0]  i_cmd_dp_write;
input  wire [0:0]  i_cmd_reset;
input  wire [0:0]  i_cmd_config;

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
assign reset_bus       = bus_reset_event && (i_phase == 0) && !strobe_on;
assign bus_start       = bus_reset_event && (i_phase == 1) &&  strobe_on;
assign bus_active      = !i_reset && !i_stalled && !bus_out_of_reset;
assign o_bus_strobe    = (i_phase == 1) && strobe_on;

// events phases

// wire   en_bus_send;
// wire   en_bus_recv;
// wire   en_bus_ecmd;

// assign en_bus_send = bus_active && i_en_bus_send;
// assign en_bus_recv = bus_active && i_en_bus_recv;
// assign en_bus_ecmd = bus_active && i_en_bus_ecmd;

wire [0:0] phase_0;
wire [0:0] phase_1;
wire [0:0] phase_2;
wire [0:0] phase_3;

assign phase_0 = bus_active && (i_phase == 0);
assign phase_1 = bus_active && (i_phase == 1);
assign phase_2 = bus_active && (i_phase == 2);
assign phase_3 = bus_active && (i_phase == 3);

/******************************************************************************
 *
 * state machine events
 *
 ****************************************************************************/

// tests on last_cmd
reg  [3:0] last_cmd;

wire [0:0] last_cmd_pc_read;
wire [0:0] last_cmd_dp_read;
wire [0:0] last_cmd_dp_write;
wire [0:0] last_cmd_load_pc;
wire [0:0] last_cmd_load_dp;

assign last_cmd_pc_read  = (last_cmd == `BUSCMD_PC_READ);
assign last_cmd_dp_read  = (last_cmd == `BUSCMD_DP_READ);
assign last_cmd_dp_write = (last_cmd == `BUSCMD_DP_WRITE);
assign last_cmd_load_pc  = (last_cmd == `BUSCMD_LOAD_PC);
assign last_cmd_load_dp  = (last_cmd == `BUSCMD_LOAD_DP);


/******************************************************************************
 *
 * THE EVIL STATE MACHINE !
 *
 *****************************************************************************/

// actual commands
reg  [0:0] cmd_pc_read_s;
wire [0:0] do_cmd_pc_read;
assign do_cmd_pc_read = phase_0 && !cmd_pc_read_s &&
                        (cmd_dp_write_D_s || cmd_config_D_s || cmd_reset_S_s);

reg  [0:0] cmd_dp_write_s;
reg  [0:0] cmd_dp_write_D_s;
wire [0:0] do_cmd_dp_write;
wire [0:0] do_cmd_dp_write_US;
wire [0:0] do_cmd_dp_write_ST;
wire [0:0] do_cmd_dp_write_C;
assign do_cmd_dp_write    = phase_0 && i_cmd_dp_write && last_cmd_dp_read;
assign do_cmd_dp_write_US = phase_0 && i_cmd_dp_write && last_cmd_dp_write;
assign do_cmd_dp_write_ST = phase_3 && !i_read_stall && !i_cmd_dp_write && last_cmd_dp_write;
assign do_cmd_dp_write_C  = phase_3 && cmd_dp_write_D_s && cmd_pc_read_s; 

wire [0:0] do_cmd_load_pc;
assign do_cmd_load_pc = phase_0 && i_cmd_load_pc; 

wire [0:0] do_cmd_load_dp;
assign do_cmd_load_dp = phase_0 && i_cmd_load_dp; 

reg  [0:0] cmd_config_S_s;
reg  [0:0] cmd_config_D_s;
wire [0:0] do_cmd_config_ST;
wire [0:0] do_cmd_config_0;
wire [0:0] do_cmd_config_D_s;
wire [0:0] do_cmd_config_US;
wire [0:0] do_cmd_config_C;
assign do_cmd_config_ST  = phase_1 && i_cmd_config && !cmd_config_S_s;
assign do_cmd_config_0   = phase_0 && i_cmd_config && !cmd_config_S_s;
assign do_cmd_config_D_s = phase_3 && cmd_config_S_s && is_loop_finished;
assign do_cmd_config_US  = phase_1 && cmd_config_D_s && cmd_pc_read_s;
assign do_cmd_config_C   = phase_2 && cmd_config_D_s && cmd_pc_read_s;

reg  [0:0] cmd_reset_S_s;
wire [0:0] do_cmd_reset_ST;
wire [0:0] do_cmd_reset;
wire [0:0] do_cmd_reset_US;
wire [0:0] do_cmd_reset_C;
assign do_cmd_reset_ST = phase_3 && i_cmd_reset && !cmd_reset_S_s && !cmd_pc_read_s;
assign do_cmd_reset    = phase_0 && i_cmd_reset && !cmd_reset_S_s && !cmd_pc_read_s;
assign do_cmd_reset_US = phase_3 && i_cmd_reset && cmd_reset_S_s && cmd_pc_read_s;
assign do_cmd_reset_C  = phase_0 && i_cmd_reset && cmd_reset_S_s && cmd_pc_read_s;

// automatic stuff

wire [0:0] do_auto_pc_read;
assign do_auto_pc_read = phase_3 && last_cmd_load_pc && addr_loop_done;

wire [0:0] do_auto_dp_read;
assign do_auto_dp_read = phase_3 && last_cmd_load_dp && addr_loop_done;

wire [0:0] do_read_en;
wire [0:0] do_read_pc;
wire [0:0] do_read_strobe;
assign do_read_en     = !i_read_stall && last_cmd_pc_read;
assign do_read_strobe = phase_0 && do_read_en;
assign do_read_pc     = phase_1 && do_read_en;


wire [0:0] en_write_dp;
wire [0:0] do_write_dp;
wire [0:0] do_write_strobe;
assign en_write_dp     = !o_stall_alu && i_cmd_dp_write && last_cmd_dp_write;
assign do_write_strobe = phase_0 && en_write_dp;
assign do_write_dp     = phase_0 && en_write_dp;

wire [0:0] do_strobe;
assign do_strobe = do_read_strobe || do_write_strobe;

wire [0:0] do_read_stalled_by_alu;
assign do_read_stalled_by_alu = phase_1 && i_read_stall && last_cmd_pc_read;

wire [0:0] do_unstall;
assign do_unstall = o_stall_alu &&
                    (do_cmd_dp_write_US || do_cmd_dp_write_C ||
                     do_cmd_config_US || do_cmd_reset_US);

wire [0:0] do_clean;
assign do_clean = do_cmd_dp_write_C || do_cmd_config_C || do_cmd_reset_C;

reg  [2:0] addr_loop_counter;
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
                            do_cmd_load_pc || 
                            do_cmd_load_dp || 
                            do_cmd_config_0);
assign do_run_addr_loop = phase_0 && run_addr_loop && !is_loop_finished;
assign will_loop_finish = addr_loop_counter == 4;
assign is_loop_finished = addr_loop_counter == 5;
assign do_reset_loop_counter = phase_3 && is_loop_finished;

wire [0:0] do_remove_strobe;
assign do_remove_strobe = phase_1 && strobe_on;

/******************************************************************************
 *
 * the controller itself
 *
 ****************************************************************************/

initial begin

  `ifdef SIM
  // $monitor("BUS - ph %0d | irs %b | icdpw %b | cprs %b | lcdpw %b", i_phase, i_read_stall, i_cmd_dp_write, cmd_pc_read_s, last_cmd_dp_write); 
//            i_phase, o_stall_alu, o_bus_reset, strobe_on, o_bus_strobe, o_bus_cmd_data);
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
    // local states

    // address loop
    init_addr_loop    <= 0;
    run_addr_loop     <= 0;
    addr_loop_counter <= 0;
    addr_loop_done    <= 0;

    cmd_pc_read_s     <= 0;
    cmd_dp_write_s    <= 0;
    cmd_config_S_s    <= 0;
    cmd_config_D_s    <= 0;
    cmd_reset_S_s     <= 0;
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
   * here starts the "FUN"
   *
   */

  if (do_cmd_pc_read) begin
    $display("BUS_CTRL %1d: [%d] PC_READ", i_phase, i_cycle_ctr);
    cmd_pc_read_s    <= 1;        
    last_cmd         <= `BUSCMD_PC_READ;
    o_bus_data       <= `BUSCMD_PC_READ;
    strobe_on        <= 1;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
  end

  if (do_cmd_dp_write) begin
    $display("BUS_CTRL %1d: [%d] DP_WRITE", i_phase, i_cycle_ctr);
    cmd_dp_write_s    <= 1;        
    last_cmd         <= `BUSCMD_DP_WRITE;
    o_bus_data       <= `BUSCMD_DP_WRITE;
    strobe_on        <= 1;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
  end

  if (do_cmd_dp_write_ST) begin
    $display("BUS_CTRL %1d: [%d] stall after dp_write", i_phase, i_cycle_ctr);
    o_stall_alu      <= 1;
    cmd_dp_write_D_s <= 1;
  end

  if (do_cmd_load_pc) begin
    $display("BUS_CTRL %1d: [%d] LOAD_PC [%5h]", i_phase, i_cycle_ctr, i_address);
    last_cmd         <= `BUSCMD_LOAD_PC;
    o_bus_data       <= `BUSCMD_LOAD_PC;
    strobe_on        <= 1;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
    init_addr_loop   <= 1;
  end

  if (do_cmd_load_dp) begin
    $display("BUS_CTRL %1d: [%d] LOAD_DP [%5h]", i_phase, i_cycle_ctr, i_address);
    last_cmd         <= `BUSCMD_LOAD_DP;
    o_bus_data       <= `BUSCMD_LOAD_DP;
    strobe_on        <= 1;
    o_bus_cmd_data   <= 0;
    o_stall_alu      <= 1;
    init_addr_loop   <= 1;
  end

/*
 *
 *
 *
 */

  if (do_cmd_config_ST) begin
    // $display("BUS_CTRL %1d: [%d] configure stall", i_phase, i_cycle_ctr);
    o_stall_alu      <= 1;
  end

  if (do_cmd_config_0) begin
    $display("BUS_CTRL %1d: [%d] CONFIGURE [%5h]", i_phase, i_cycle_ctr, i_address);
    cmd_config_S_s  <= 1;
    last_cmd        <= `BUSCMD_CONFIGURE;
    o_bus_data      <= `BUSCMD_CONFIGURE;
    strobe_on       <= 1;
    o_bus_cmd_data  <= 0;
    o_stall_alu     <= 1;
    init_addr_loop  <= 1;
  end

  if (do_cmd_config_D_s) begin
    // $display("BUS_CTRL %1d: [%d] set cmd_config_D_s", i_phase, i_cycle_ctr);
    cmd_config_D_s  <= 1;
  end

/*
 *
 *
 *
 */

  if (do_cmd_reset_ST) begin
    // $display("BUS_CTRL %1d: [%d] reset stall", i_phase, i_cycle_ctr);
    o_stall_alu      <= 1;
  end

  if (do_cmd_reset) begin
    $display("BUS_CTRL %1d: [%d] RESET", i_phase, i_cycle_ctr);
    cmd_reset_S_s  <= 1;
    last_cmd        <= `BUSCMD_RESET;
    o_bus_data      <= `BUSCMD_RESET;
    strobe_on       <= 1;
    o_bus_cmd_data  <= 0;
    o_stall_alu     <= 1;
  end


  // address loop handling

  if (do_init_addr_loop) begin
    // $display("BUS_CTRL %1d: [%d] init addr loop", i_phase, i_cycle_ctr);
    addr_loop_done    <= 0;
    addr_loop_counter <= 0;
    run_addr_loop     <= 1;
    init_addr_loop    <= 0;
  end

  if (do_run_addr_loop) begin
    $write("BUS_CTRL %1d: [%d] ADDR(%0d)-> %h ", 
           i_phase, i_cycle_ctr, addr_loop_counter,
           i_address[addr_loop_counter*4+:4]);
    if (will_loop_finish) $write("done");
    $write("\n");

    o_bus_data <= i_address[addr_loop_counter*4+:4];
    strobe_on  <= 1;
    // clean up at the end of loop
    addr_loop_counter <= addr_loop_counter + 1;
    run_addr_loop     <= !will_loop_finish;
    addr_loop_done    <= will_loop_finish; 
  end

  // cleanup functions

  if (do_auto_pc_read) begin
    $display("BUS_CTRL %1d: [%d] auto PC_READ", i_phase, i_cycle_ctr);
    last_cmd <= `BUSCMD_PC_READ;
    o_stall_alu <= 0;
  end

  if (do_auto_dp_read) begin
    $display("BUS_CTRL %1d: [%d] auto DP_READ", i_phase, i_cycle_ctr);
    last_cmd <= `BUSCMD_DP_READ;
    o_stall_alu <= 0;
  end

  if (do_reset_loop_counter) begin
    // $display("BUS_CTRL %1d: [%d] reset loop counter", i_phase, i_cycle_ctr);
    addr_loop_counter <= 0;
  end

  if (do_unstall) begin
    $display("BUS_CTRL %1d: [%d] remove stall", i_phase, i_cycle_ctr);
    o_stall_alu <= 0;
  end

  if (do_clean) begin
    $display("BUS_CTRL %1d: [%d] cleanup", i_phase, i_cycle_ctr);
    cmd_pc_read_s    <= 0;
    cmd_dp_write_s   <= 0;
    cmd_dp_write_D_s <= 0;
    cmd_config_S_s   <= 0;
    cmd_config_D_s   <= 0;
    cmd_reset_S_s    <= 0;
  end

  /*
   *
   * Reading from the bus
   *
   */

  if (do_strobe) begin
    strobe_on <= 1;
  end

  if (do_read_pc) begin
    o_nibble <= i_bus_data;
    $display("BUS_CTRL %1d: [%d] READ %h", i_phase, i_cycle_ctr, i_bus_data);
  end

  if (do_write_dp) begin
    $display("BUS_CTRL %1d: [%d] WRITE %h", i_phase, i_cycle_ctr, i_nibble);
    o_bus_data <= i_nibble;
  end

  if (do_read_stalled_by_alu) begin
    $display("BUS_CTRL %1d: [%d] read stall (alu)", i_phase, i_cycle_ctr);
  end

  if (do_remove_strobe) begin
    strobe_on   <= 0;
    o_bus_cmd_data <= 1;
  end


end

endmodule

`endif