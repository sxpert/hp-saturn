`include "bus_commands.v"

`ifndef _HP48_IO_RAM
`define _HP48_IO_RAM

/**************************************************************************************************
 *
 * I/O ram 
 * length: 64 nibbles
 *
 *
 */


module hp48_io_ram (
	input				clk,
	input				reset,
	input		[19:0]	address,
	input		[3:0]	command,
	input		[3:0]	nibble_in,
	output	reg [3:0]	nibble_out,
	output	reg			io_ram_active,
	output	reg			io_ram_error
);

localparam IO_RAM_LEN		= 64;

// localparam BUSCMD_DP_WRITE	= C_BUSCMD_DP_WRITE;
// localparam BUSCMD_CONFIGURE = C_BUSCMD_CONFIGURE;


reg	[0:0]	configured;
reg [19:0]	base_addr;
reg [19:0]	pc_ptr;
reg [19:0]	data_ptr;
reg [3:0]	io_ram [0:IO_RAM_LEN-1];

/*
 *
 *
 */

initial
	begin
`ifdef SIM
		$display("io_ram: set unconfigured");
`endif
		configured = 0;
`ifdef SIM
		$display("io_ram: reset error flag");
`endif
		io_ram_error = 1'b0;	
`ifdef SIM
		$display("io_ram: setting base address to 0");
`endif
		base_addr = 0;
`ifdef SIM
		$display("io_ram: setting data pointer to 0");
`endif
		data_ptr = 0;
`ifdef SIM
		$display("io_ram: initializing to 0");
`endif
		for (base_addr = 0; base_addr < IO_RAM_LEN; base_addr++)
			begin
`ifdef SIM
				$write(".");
`endif
				io_ram[base_addr] <= 0; 
			end
`ifdef SIM	
		$write("\n");
		$display("io_ram: initialized");
`endif
	end

/*
 *
 *
 */

always @(*)
	begin
		io_ram_active = 0;
		if ((command==`BUSCMD_PC_READ)|(command==`BUSCMD_DP_READ)|
			(command==`BUSCMD_PC_WRITE)|(command==`BUSCMD_PC_WRITE))
			io_ram_active = ((base_addr>=data_ptr)&(data_ptr<base_addr+IO_RAM_LEN))&(configured);
	end

always @(posedge clk)
    case (command)
        `BUSCMD_LOAD_PC:
            begin
`ifdef SIM
                $display("io_ram: LOAD_PC %5h", address);
`endif
                pc_ptr <= address;
            end
    endcase

always @(negedge clk)
	if ((~reset)&(~io_ram_error))
		case (command)
			`BUSCMD_NOP: begin end				// do nothing	
			`BUSCMD_PC_READ:	
				begin
					// test if write can be done
					if (io_ram_active)
						begin
							nibble_out <= io_ram[pc_ptr - base_addr];
`ifdef SIM
							$display("io_ram: PC_READ %5h %h | OK", data_ptr, nibble_in); 
`endif
						end
// `ifdef SIM
// 					else
// 						$display("io_ram: PC_READ %5h %h | NOK - IO_RAM not active (conf: %b)", data_ptr, nibble_in, configured); 
// `endif
					pc_ptr <= pc_ptr + 1;
				end
			`BUSCMD_DP_WRITE:
				begin
					// test if write can be done
					if (io_ram_active)
						begin
							io_ram[data_ptr - base_addr] <= nibble_in;
`ifdef SIM
							$display("io_ram: DP_WRITE %5h %h | OK", data_ptr, nibble_in); 
`endif
						end
`ifdef SIM
					else
							$display("io_ram: DP_WRITE %5h %h | NOK - IO_RAM not active (conf: %b)", data_ptr, nibble_in, configured); 
`endif
					data_ptr <= data_ptr + 1;
				end
			`BUSCMD_LOAD_PC: begin end // done on posedge
			`BUSCMD_LOAD_DP:
				begin
`ifdef SIM
					//$display("io_ram: LOAD_DP %5h", address);
`endif
					data_ptr <= address;
				end
			`BUSCMD_CONFIGURE:
				begin
`ifdef SIM
					$display("io_ram: configure at %5h len %d", address, IO_RAM_LEN);
`endif
					base_addr <= address;
					configured <= 1;
				end
			default:
				begin
`ifdef SIM
					$display("io_ram: unhandled command %h", command);
`endif
					io_ram_error <= 1;
				end
		endcase

endmodule

`endif
