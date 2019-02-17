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
  i_read_pc,
  i_write_dp,
  i_cmd_reset,
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
input  wire [0:0]  i_read_pc;
input  wire [0:0]  i_write_dp;
input  wire [0:0]  i_cmd_reset;
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

//   $monitor("MONITOR   : strb %b | o_bus_data %h | i_bus_data %h", o_bus_strobe, o_bus_data, i_bus_data);
  `endif
end

reg [3:0]  last_cmd;
reg [2:0]  addr_cnt;
reg [0:0]  send_addr;
reg [0:0]  reset_sent;
reg [0:0]  send_pc_read;
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
    reset_sent       <= 0;
    send_pc_read     <= 0;
  end

  /*
   *
   * sending commands or data to the bus
   *
   */
  if (en_bus_send) begin

    /*
     * Sending LOAD_PC or LOAD_DP
     */

    if (i_load_pc) begin
      $display("BUS_SEND %0d: [%d] LOAD_PC %h", `PH_BUS_SEND, i_cycle_ctr, i_address);
      o_bus_data <= `BUSCMD_LOAD_PC;
      last_cmd   <= `BUSCMD_LOAD_PC;
    end

    if (i_load_dp) begin
      $display("BUS_SEND %0d: [%d] LOAD_DP %h", `PH_BUS_SEND, i_cycle_ctr, i_address);
      o_bus_data <= `BUSCMD_LOAD_DP;
      last_cmd   <= `BUSCMD_LOAD_DP;
    end

    if (i_load_pc || i_load_dp) begin
      o_stalled_by_bus <= 1;
      o_bus_cmd_data   <= 0;
      addr_cnt         <= 0;
      send_addr        <= 1;
      o_bus_strobe     <= 1;
    end

    // sending address bits
    if (send_addr) begin
      $display("BUS_SEND %0d: [%d] addr[%0d] %h =>", 
               `PH_BUS_SEND, i_cycle_ctr, addr_cnt,  i_address[addr_cnt*4+:4]);
      o_bus_data <= i_address[addr_cnt*4+:4];
      addr_cnt <= addr_cnt + 1;
      o_bus_strobe   <= 1;
    end

    /*
     * send the PC_READ command to restore the instruction flow
     * after a data transfer
     */

    if (i_read_pc || send_pc_read) begin
      if (last_cmd != `BUSCMD_PC_READ) begin
        $display("BUS_SEND %0d: [%d] PC_READ", `PH_BUS_SEND, i_cycle_ctr);
        o_bus_data   <= `BUSCMD_PC_READ;
        last_cmd     <= `BUSCMD_PC_READ;
        send_pc_read <= 0;
      end
      
      o_bus_strobe <= 1;
    end

    if ((last_cmd == `BUSCMD_PC_READ) && !i_read_stall)
      o_bus_strobe <= 1;

    /*
     * writing data to the bus, 
     * send DP_WRITE first if necessary
     */

    if (i_write_dp && (addr_cnt == 5)) begin
      if (last_cmd != `BUSCMD_DP_WRITE) begin
        $display("BUS_SEND %0d: [%d] DP_WRITE", `PH_BUS_SEND, i_cycle_ctr);
        o_bus_data   <= `BUSCMD_DP_WRITE;
        last_cmd     <= `BUSCMD_DP_WRITE;
        o_bus_strobe <= 1;
      end else begin
        $display("BUS_SEND %0d: [%d] WRITE %h =>", `PH_BUS_SEND, i_cycle_ctr, i_nibble);
        o_bus_data   <= i_nibble;
        o_bus_strobe <= 1;
      end
    end

    if (i_cmd_reset && !reset_sent) begin
      $display("BUS_SEND %0d: [%d] RESET", `PH_BUS_SEND, i_cycle_ctr);
      o_bus_data   <= `BUSCMD_RESET;
      last_cmd     <= `BUSCMD_RESET;
      reset_sent   <= 1;
      o_bus_strobe <= 1;
    end


  end
  /*
   *
   * reading data from the bus
   *
   */


  if (en_bus_recv) begin
  
    if (!i_read_stall)
      case (last_cmd)
      `BUSCMD_PC_READ: begin
          $display("BUS_RECV %0d: [%d] <= READ [%5h] %h", `PH_BUS_RECV, i_cycle_ctr, local_pc, rom[local_pc[`ROMBITS-1:0]]); 
          o_nibble <= rom[local_pc[`ROMBITS-1:0]];
          local_pc <= local_pc + 1;
      end 
      endcase
    else 
      if (!o_stalled_by_bus) begin
        $write("BUS_RECV %0d: [%d] STALLED (last ", `PH_BUS_RECV, i_cycle_ctr);  
        case (last_cmd)
          `BUSCMD_PC_READ: $write("PC_READ");
          `BUSCMD_RESET:   $write("RESET");
          default: $write("%h", last_cmd);
        endcase
        $display(")");
      end

  /*
   *
   * resets the bus automatically
   *
   */

    o_bus_strobe <= 0;
    o_bus_cmd_data <= 1;

  end


  // command automatic switchover
  if (en_bus_ecmd) begin

    if (i_cmd_reset && !reset_sent)
      o_stalled_by_bus <= 1;
    
    case (last_cmd)
      `BUSCMD_LOAD_PC,
      `BUSCMD_LOAD_DP:
        if (send_addr && (addr_cnt == 5)) begin
          $display("BUS_ECMD %0d: [%d] <= %sC_READ mode", 
                   `PH_BUS_ECMD, i_cycle_ctr, 
                   (last_cmd == `BUSCMD_LOAD_PC)?"P":"D");
          last_cmd <= (last_cmd == `BUSCMD_LOAD_PC)?`BUSCMD_PC_READ:`BUSCMD_DP_READ;
          case (last_cmd)
             `BUSCMD_LOAD_PC: local_pc <= i_address;
             `BUSCMD_LOAD_DP: local_dp <= i_address;
          endcase
          send_addr <= 0;
          o_stalled_by_bus <= 0;
        end   
      `BUSCMD_PC_READ: begin
        if (o_stalled_by_bus && reset_sent) begin
        //   $display("BUS_ECMD %0d: [%d] (pc_read unstall)", `PH_BUS_ECMD, i_cycle_ctr); 
          o_stalled_by_bus <= 0;
        end  
      end
      `BUSCMD_RESET: begin
        if (o_stalled_by_bus && reset_sent) begin
        //   $display("BUS_ECMD %0d: [%d] (reset, send pc_read)", `PH_BUS_ECMD, i_cycle_ctr);
          send_pc_read <= 1;
        end
      end
    endcase



  end


end

endmodule

`endif