`ifndef _SATURN_BUS_CTRL
`define _SATURN_BUS_CTRL

`include "def-clocks.v"
`include "def-buscmd.v"

module saturn_bus_ctrl (
  // basic stuff
  i_clk,
  i_reset,
  i_cycle_ctr,
  i_en_bus_send,
  i_en_bus_recv,
  i_en_bus_ecmd,
  i_stalled,
  i_read_stall,

  o_stalled_by_bus,

  // bus i/o
  i_bus_data,
  o_bus_data,
  o_bus_strobe,
  o_bus_cmd_data,

  // interface to the rest of the machine
  i_alu_pc,
  i_address,
  i_load_pc,
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
input  wire [31:0] i_cycle_ctr;
input  wire [0:0]  i_en_bus_send;
input  wire [0:0]  i_en_bus_recv;
input  wire [0:0]  i_en_bus_ecmd;
input  wire [0:0]  i_stalled;
input  wire [0:0]  i_read_stall;

output reg  [0:0]  o_stalled_by_bus;

input  wire [3:0]  i_bus_data;
output reg  [3:0]  o_bus_data;
output reg  [0:0]  o_bus_strobe;
output reg  [0:0]  o_bus_cmd_data;

input  wire [19:0] i_alu_pc;
input  wire [19:0] i_address;
input  wire [0:0]  i_load_pc;
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

wire   en_bus_send;
wire   en_bus_recv;
wire   en_bus_ecmd;

assign en_bus_send = i_en_bus_send && !i_stalled;
assign en_bus_recv = i_en_bus_recv && !i_stalled;
assign en_bus_ecmd = i_en_bus_ecmd && !i_stalled;

/******************************************************************************
 *
 * state machine events
 *
 ****************************************************************************/

// tests on last_cmd

wire [0:0] last_cmd_pc_read;
wire [0:0] last_cmd_dp_read;
wire [0:0] last_cmd_dp_write;

assign last_cmd_pc_read  = (last_cmd == `BUSCMD_PC_READ);
assign last_cmd_dp_read  = (last_cmd == `BUSCMD_DP_READ);
assign last_cmd_dp_write = (last_cmd == `BUSCMD_DP_WRITE);

// declarations

reg  [0:0] cmd_pc_read_s;
reg  [0:0] dp_read_s;
reg  [0:0] cmd_dp_write_s;
reg  [0:0] cmd_load_dp_s;
reg  [0:0] cmd_config_s;
reg  [0:0] cmd_reset_s;

wire [0:0] addr_s;

wire [0:0] do_cmd_pc_read;
wire [0:0] do_display_stalled; 

wire [0:0] do_cmd_load_dp;
wire [0:0] do_dp_read_data;
wire [0:0] do_dp_read_data_sc;
wire [0:0] do_dp_read_data_uc;
wire [0:0] do_pc_read_after_dp_read; 
wire [0:0] do_cleanup_after_dp_read;

wire [0:0] do_cmd_dp_write;
wire [0:0] cmd_dp_write_data;
wire [0:0] do_dp_write_data;
wire [0:0] do_pc_read_after_dp_write;
wire [0:0] cmd_load_dp_dp_write_uc;

wire [0:0] do_cmd_config;
wire [0:0] do_pc_read_after_config;
wire [0:0] cmd_config_sc;
wire [0:0] cmd_config_uc;

wire [0:0] do_cmd_reset;
wire [0:0] do_pc_read_after_reset;
wire [0:0] cmd_reset_sc;
wire [0:0] cmd_reset_uc;

wire [0:0] do_cleanup;
wire [0:0] do_stall;
wire [0:0] do_unstall;
wire [0:0] do_stop_loop;

// assigns

assign addr_s = addr_cnt == 5;

assign do_cmd_load_dp            = i_cmd_load_dp && !cmd_load_dp_s;

assign do_dp_read_data           = i_cmd_dp_read && cmd_load_dp_s && (addr_s || dp_read_s);
assign do_dp_read_data_sc        = i_cmd_dp_read && cmd_load_dp_s && addr_s && !dp_read_s;
assign do_dp_read_data_uc        = i_cmd_dp_read && cmd_load_dp_s && addr_s && dp_read_s;
assign do_pc_read_after_dp_read  = i_read_stall && !i_cmd_dp_read && cmd_load_dp_s && !addr_s && dp_read_s;
assign do_cleanup_after_dp_read  = !i_read_stall && !i_cmd_dp_read && cmd_load_dp_s && !addr_s && dp_read_s;

assign do_cmd_dp_write           = i_cmd_dp_write && cmd_load_dp_s && addr_s && !cmd_dp_write_s;
assign cmd_dp_write_data         = i_cmd_dp_write && cmd_load_dp_s && addr_s && cmd_dp_write_s;
assign do_dp_write_data          = en_bus_send && cmd_dp_write_data && last_cmd_dp_write;
assign do_pc_read_after_dp_write = !i_cmd_dp_write && cmd_load_dp_s && cmd_dp_write_s;
assign cmd_load_dp_dp_write_uc   = cmd_load_dp_s && cmd_dp_write_s && cmd_pc_read_s;

assign do_cmd_config             = i_cmd_config && !cmd_config_s;
assign do_pc_read_after_config   = i_cmd_config && cmd_config_s && addr_s;
assign cmd_config_sc             = !o_stalled_by_bus && i_cmd_config && !cmd_config_s;
assign cmd_config_uc             = cmd_config_s && cmd_pc_read_s;

assign do_cmd_reset              = i_cmd_reset && !cmd_reset_s;
assign do_pc_read_after_reset    = i_cmd_reset && cmd_reset_s;
assign cmd_reset_sc              = !o_stalled_by_bus && i_cmd_reset && !cmd_reset_s;
assign cmd_reset_uc              = cmd_reset_s && cmd_pc_read_s;

assign do_cmd_pc_read            = !cmd_pc_read_s && 
                                   (do_pc_read_after_dp_read ||
                                    do_pc_read_after_dp_write ||
                                    do_pc_read_after_config || 
                                    do_pc_read_after_reset);

assign do_display_stalled        = en_bus_recv && i_read_stall && !o_stalled_by_bus &&
                                   !(do_cmd_pc_read ||
                                     do_dp_read_data ||
                                     do_pc_read_after_dp_read ||
                                     do_cmd_dp_write ||
                                     cmd_dp_write_data ||
                                     do_pc_read_after_dp_write);

assign do_cleanup                = en_bus_send &&
                                   (do_cleanup_after_dp_read ||
                                    cmd_load_dp_dp_write_uc ||
                                    cmd_config_uc ||
                                    cmd_reset_uc);

assign do_stall                  = en_bus_ecmd &&
                                   (do_dp_read_data_sc || 
                                    cmd_reset_sc || 
                                    cmd_config_sc);

assign do_unstall                = en_bus_ecmd &&
                                   (do_dp_read_data_uc ||
                                    cmd_load_dp_dp_write_uc ||
                                    cmd_config_uc ||
                                    cmd_reset_uc);

assign do_stop_loop              = en_bus_ecmd && addr_s;                                    

/******************************************************************************
 *
 * test rom
 *
 ****************************************************************************/

`ifdef SIM
`define ROMBITS 20
`else 
`define ROMBITS 12
`endif

reg [3:0] rom [0:2**`ROMBITS-1];

wire [0:0]          do_read_from_bus;
wire [0:0]          use_pc_as_pointer;
wire [0:0]          use_dp_as_pointer;
wire [0:0]          do_read_from_bus_with_pc;
wire [0:0]          do_read_from_bus_with_dp;
wire [`ROMBITS-1:0] read_pointer; 

assign do_read_from_bus         = en_bus_recv && (!i_read_stall || do_dp_read_data) && (last_cmd_pc_read || last_cmd_dp_read);
assign use_pc_as_pointer        = last_cmd_pc_read;
assign use_dp_as_pointer        = last_cmd_dp_read;
assign read_pointer             = use_pc_as_pointer?local_pc[`ROMBITS-1:0]:local_dp[`ROMBITS-1:0];
assign do_read_from_bus_with_pc = do_read_from_bus && use_pc_as_pointer;
assign do_read_from_bus_with_dp = do_read_from_bus && use_dp_as_pointer;

/******************************************************************************
 *
 * the controller itself
 *
 ****************************************************************************/

initial begin
//   `ifdef SIM
  $readmemh("rom-gx-r.hex", rom, 0, 2**`ROMBITS-1);
//   $readmemh( "testrom-2.hex", rom);

  `ifdef SIM
//   $monitor({"o_stalled_by_bus %b | i_read_stall %b | i_cmd_dp_read %b |",
//             " cmd_load_dp_s %b | addr_s %b | dp_read_s %b |do_dp_read_data %b"}, 
//            o_stalled_by_bus, i_read_stall, i_cmd_dp_read, cmd_load_dp_s, 
//            addr_s, dp_read_s, do_dp_read_data);
  `endif
end

reg [3:0]  last_cmd;
reg [2:0]  addr_cnt;
reg [0:0]  send_addr;
reg [19:0] local_pc;
reg [19:0] local_dp;

always @(posedge i_clk) begin
  if (i_reset) begin
    last_cmd         <= 0;
    o_stalled_by_bus <= 0;
    o_bus_strobe     <= 0;
    o_bus_cmd_data   <= 1; // 1 is the default level
    addr_cnt         <= 0;
    send_addr        <= 0;

    cmd_pc_read_s    <= 0;
    dp_read_s        <= 0;
    cmd_dp_write_s   <= 0;
    cmd_load_dp_s    <= 0;
    cmd_config_s     <= 0;
    cmd_reset_s      <= 0;
  end

  /*
   * reset flags
   */
  if (do_cleanup) begin
  //   $display("--------------------------------------------- BUS STATES CLEANUP");
    cmd_pc_read_s  <= 0;
    dp_read_s      <= 0;
    cmd_dp_write_s <= 0;
    cmd_load_dp_s  <= 0;
    cmd_config_s   <= 0;
    cmd_reset_s    <= 0;
  end

  /*
   *
   * sending commands or data to the bus
   *
   */
  if (en_bus_send) begin

    /*
     * send the PC_READ command to restore the instruction flow
     * after a data transfer
     */

    if (do_cmd_pc_read) begin
      $display("BUS_SEND %0d: [%d] PC_READ", `PH_BUS_SEND, i_cycle_ctr);
      o_bus_data    <= `BUSCMD_PC_READ;
      last_cmd      <= `BUSCMD_PC_READ;
      cmd_pc_read_s <= 1;
      o_bus_strobe  <= 1;
    end

    if ((last_cmd == `BUSCMD_PC_READ) && !i_read_stall)
      o_bus_strobe <= 1;


    if (do_cmd_dp_write) begin
      $display("BUS_SEND %0d: [%d] DP_WRITE", `PH_BUS_SEND, i_cycle_ctr);
      o_bus_data     <= `BUSCMD_DP_WRITE;
      last_cmd       <= `BUSCMD_DP_WRITE;
      cmd_dp_write_s <= 1;
      o_bus_strobe   <= 1; 
    end


    /*
     * Sending LOAD_PC or LOAD_DP
     */

    if (i_load_pc) begin
      $display("BUS_SEND %0d: [%d] LOAD_PC %h", `PH_BUS_SEND, i_cycle_ctr, i_address);
      o_bus_data <= `BUSCMD_LOAD_PC;
      last_cmd   <= `BUSCMD_LOAD_PC;
    end

    if (do_cmd_load_dp) begin
      $display("BUS_SEND %0d: [%d] LOAD_DP %h", `PH_BUS_SEND, i_cycle_ctr, i_address);
      o_bus_data <= `BUSCMD_LOAD_DP;
      last_cmd   <= `BUSCMD_LOAD_DP;
      cmd_load_dp_s <= 1;
    end

    if (do_cmd_config) begin
      $display("BUS_SEND %0d: [%d] CONFIGURE %h", `PH_BUS_SEND, i_cycle_ctr, i_address);
      o_bus_data   <= `BUSCMD_CONFIGURE;
      last_cmd     <= `BUSCMD_CONFIGURE;
      cmd_config_s <= 1;
    end

    if (do_cmd_reset) begin
      $display("BUS_SEND %0d: [%d] RESET", `PH_BUS_SEND, i_cycle_ctr);
      o_bus_data   <= `BUSCMD_RESET;
      last_cmd     <= `BUSCMD_RESET;
      cmd_reset_s  <= 1;
      o_bus_strobe <= 1;
    end

    // configure loop to send i_address to the bus
    // used for LOAD_PC, LOAD_DP, CONFIGURE,
    if (i_load_pc || do_cmd_load_dp || do_cmd_config) begin
      o_stalled_by_bus <= 1;
      o_bus_cmd_data   <= 0;
      addr_cnt         <= 0;
      send_addr        <= 1;
      o_bus_strobe     <= 1;
    end

    // sending address bits
    if (send_addr) begin
`ifdef SIM
      $display("BUS_SEND %0d: [%d] addr[%0d] %h =>", 
               `PH_BUS_SEND, i_cycle_ctr, addr_cnt,  i_address[addr_cnt*4+:4]);
`endif
      o_bus_data <= i_address[addr_cnt*4+:4];
      addr_cnt <= addr_cnt + 1;
      o_bus_strobe   <= 1;
    end
  end


/******************************************************************************
 *
 * writing data to the bus, 
 * will wait for DP_WRITE to be sent
 *
 ****************************************************************************/

  if (do_dp_write_data) begin
    $display("BUS_SEND %0d: [%d] WRITE %h =>", `PH_BUS_SEND, i_cycle_ctr, i_nibble);
    o_bus_data   <= i_nibble;
    o_bus_strobe <= 1;
  end




  /****************************************************************************
   *
   * reading data from the bus
   *
   ***************************************************************************/

  /* 
   * only display during simulation
   */
`ifdef SIM

  if (do_read_from_bus)
    $display("BUS_RECV %0d: [%d] <= READ(%s) [%5h] %h", 
             `PH_BUS_RECV, i_cycle_ctr, use_pc_as_pointer?"PC":"DP",
             read_pointer, rom[read_pointer]);

`endif

  if (do_read_from_bus)
    o_nibble <= rom[read_pointer];


  if (do_read_from_bus_with_pc)
    local_pc <= local_pc + 1;

  if (do_read_from_bus_with_dp) begin
    local_dp <= local_dp + 1;    
    dp_read_s <= 1;
  end             

  if (do_display_stalled) begin
      $display("BUS_RECV %0d: [%d] STALLED", `PH_BUS_RECV, i_cycle_ctr);
  end

  /*
   *
   * resets the bus automatically
   *
   */
  if (en_bus_recv) begin
    o_bus_strobe <= 0;
    o_bus_cmd_data <= 1;
  end

/******************************************************************************
 *
 * execute stalling the core by the bus controller
 *
 *****************************************************************************/

  if (do_stall) begin
  //   $display("-------------------------------------- STALL");
    o_stalled_by_bus <= 1;
  end

  if (do_unstall) begin
  //   $display("-------------------------------------- NO - STALL");
    o_stalled_by_bus <= 0;
    addr_cnt <= 0;
  end

  /*
   * reset the adress sending loop
   * 
   */

  if (do_stop_loop) begin
    send_addr <= 0;
  end


  if (en_bus_ecmd) begin
  // command automatic switchover
    case (last_cmd)
      `BUSCMD_NOP: begin end
      `BUSCMD_LOAD_PC,
      `BUSCMD_LOAD_DP:
        if (send_addr && addr_s) begin
          // reset the addr count for next time
          $display("BUS_ECMD %0d: [%d] <= %s_READ mode", 
                   `PH_BUS_ECMD, i_cycle_ctr, 
                   (last_cmd == `BUSCMD_LOAD_PC)?"PC":"DP");
          last_cmd <= (last_cmd == `BUSCMD_LOAD_PC)?`BUSCMD_PC_READ:`BUSCMD_DP_READ;
          case (last_cmd)
             `BUSCMD_LOAD_PC: local_pc <= i_address;
             `BUSCMD_LOAD_DP: local_dp <= i_address;
          endcase
          send_addr <= 0;
          if (!do_dp_read_data) begin
            // $display("-------------------------------------- NO - STALL (auto-change mode)");
            o_stalled_by_bus <= 0;
          end
        end   
      `BUSCMD_PC_READ: begin end
      `BUSCMD_DP_READ: begin end
      `BUSCMD_DP_WRITE: begin end
      `BUSCMD_CONFIGURE: begin end
      `BUSCMD_RESET: begin end
      default: $display("------------ UNHANDLED BUSCMD %h", last_cmd);
    endcase
  end


end

endmodule

`endif