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
  i_load_dp,
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
input  wire [0:0]  i_load_dp;
input  wire [3:0]  i_nibble;
output reg  [3:0]  o_nibble;

/*
 * events
 */


wire en_bus_send;
assign en_bus_send = i_en_bus_send && !i_stalled;
wire en_bus_recv;
assign en_bus_recv = i_en_bus_recv && !i_stalled;
wire en_bus_ecmd;
assign en_bus_ecmd = i_en_bus_ecmd && !i_stalled;

/*
 * test rom...
 */
`ifdef SIM
`define ROMBITS 20
`else 
`define ROMBITS 10
`endif

reg [3:0] rom [0:2**`ROMBITS-1];

initial begin
  `ifdef SIM
  $readmemh("rom-gx-r.hex", rom);
  // $readmemh( "testrom-2.hex", rom);
//   $monitor("addr %5h | strb %b | c/d %b | cnt %0d | odata %h | idata %h",
//            i_address, o_bus_strobe, o_bus_cmd_data, addr_cnt, o_bus_data, i_bus_data);
  `endif
end

reg [2:0] addr_cnt;

reg [0:0] send_addr;

reg [19:0] local_pc;

always @(posedge i_clk) begin
  if (i_reset) begin
    o_stalled_by_bus <= 0;
    o_bus_strobe     <= 0;
    o_bus_cmd_data   <= 1; // 1 is the default level
    addr_cnt <= 0;
  end

  /*
   *
   * sending commands or data to the bus
   *
   */
  if (en_bus_send) begin

    if (i_load_pc) begin
      $display("BUS_SEND %0d: loading pc %h", `PH_BUS_SEND, i_address);
      o_bus_data <= `BUSCMD_LOAD_PC;
    end

    if (i_load_dp) begin
      $display("BUS_SEND %0d: loading dp %h", `PH_BUS_SEND, i_address);
      o_bus_data <= `BUSCMD_LOAD_DP;
    end

    if (i_load_pc || i_load_dp) begin
      o_stalled_by_bus <= 1;
      o_bus_cmd_data <= 0;
      addr_cnt <= 0;
      send_addr <= 1;
    end

    if (send_addr) begin
      $display("BUS_SEND %0d: send addr nibble %0d [%h]", `PH_BUS_SEND, addr_cnt,  i_address[addr_cnt*4+:4]);
      o_bus_data <= i_address[addr_cnt*4+:4];
      addr_cnt <= addr_cnt + 1;
    end

    if (!i_read_stall || send_addr)
        o_bus_strobe <= 1;
  end

  if (en_bus_ecmd && send_addr && (addr_cnt == 5)) begin
    $display("BUS_ECMD %0d: releasing stall after sending addr", `PH_BUS_ECMD);
    send_addr <= 0;
    o_stalled_by_bus = 0;
  end

  /*
   *
   * reading data from the bus
   *
   */
  if (en_bus_recv && !i_read_stall) begin
    $display("BUS_RECV %0d: [%d] nibble %h", `PH_BUS_RECV, i_cycle_ctr, rom[i_alu_pc[`ROMBITS-1:0]]); 
    o_nibble <= rom[i_alu_pc[`ROMBITS-1:0]];
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

end

endmodule

`endif