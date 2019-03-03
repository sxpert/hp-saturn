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

`default_nettype none

`ifdef SIM
module saturn_top;
`else
module saturn_top (
	clk_25mhz,
	btn,
	led
);

input  wire [0:0] clk_25mhz;
input  wire [6:0] btn;
`endif

`ifdef SIM
wire [7:0]  led;
`else
output wire [7:0] led;
wire [0:0] reset;
wire [0:0] halt;

assign reset  = btn[0]; 
`endif

saturn_bus main_bus (
`ifdef SIM
    .i_clk          (clk),
`else
    .i_clk          (clk_25mhz),
`endif
    .i_clk_en       (clk_en),
    .i_reset        (reset),
    .o_halt         (halt),
    .o_char_to_send (led)
);


`ifdef SIM
reg	 [0:0] clk;
reg	 [0:0] reset;
wire [0:0] halt;

initial begin
	$display("TOP       : starting the simulation");
	clk = 0;
	reset = 1;
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);
	reset = 0;
    $display("TOP       : reset done, waiting for instructions");
	@(posedge halt);
    $display("TOP       : instructed to stop, halt is %b", halt);
	$finish;
end

always 
    #10 clk = (clk === 1'b0);
`endif

`ifndef SIM
`define DELAY_BITS 25
`define DELAY_ZERO {`DELAY_BITS{1'b0}}
`define DELAY_ONE  {{`DELAY_BITS-1{1'b0}},1'b1}

reg [`DELAY_BITS-1:0]  delay;
`endif

reg [0:0] clk_en;


initial begin
`ifdef SIM
    clk_en = 1'b1;
`else
    delay  = `DELAY_ZERO;
    clk_en = 1'b0;
`endif
end

always @(posedge clk) begin
`ifndef SIM
    delay <= delay + `DELAY_ONE;
    if (delay[`DELAY_BITS-1]) begin
        clk_en <= 1'b1;
    end
    if (clk_en) begin
        clk_en <= 1'b0;
        delay  <= `DELAY_ZERO; 
    end
`endif

    if (reset) begin
`ifdef SIM
        clk_en <= 1'b1;
`else
        delay  <= `DELAY_ZERO;
        clk_en <= 1'b0;
`endif
    end
end

endmodule
