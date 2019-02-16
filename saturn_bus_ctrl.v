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
  `endif
end


always @(posedge i_clk) begin
  if (i_reset) 
    o_stalled_by_bus <= 0;

  if (en_bus_send) begin
    if (i_load_pc) begin
      $display("BUS_SEND %0d: loading pc %h", `PH_BUS_SEND, i_address);

      o_stalled_by_bus <= 1;
    end
    o_bus_strobe <= 1;
  end

  if (en_bus_recv && !i_read_stall) begin
    $display("BUS_RECV %0d: [%d] nibble %h", `PH_BUS_RECV, i_cycle_ctr, rom[i_alu_pc[`ROMBITS-1:0]]); 
    o_nibble <= rom[i_alu_pc[`ROMBITS-1:0]];
  end

  // this is always done to lower the strobe signal
  if (en_bus_recv)
    o_bus_strobe <= 0;
end

endmodule

`endif