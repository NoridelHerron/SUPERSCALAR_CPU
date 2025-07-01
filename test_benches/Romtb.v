
`timescale 1ns / 1ps

module tb_rom;

    reg  clk;
    reg  [9:0] addr1, addr2;
    wire [31:0] instr1, instr2;   // Instruction outputs from ROM

    // Instantiate the ROM
    rom uut (
        .clk(clk),
        .addr1(addr1),
        .addr2(addr2),
        .instr1(instr1),
        .instr2(instr2)
    );

    // Clock generator (10ns period)
    always #5 clk = ~clk;

    integer i;

    initial begin
	$display("----Starting ROM test---");
        clk = 0;
        addr1 = 0;
        addr2 = 0;

        // Wait a bit before starting
        #10;

		//Read first 10 instruction pairs from ROM
        for (i = 0; i < 40; i = i + 2) begin     //Here Set address on clock edge
            @(posedge clk);
            addr1 = i;
            addr2 = i + 1;
            @(posedge clk);
            $display("addr1 = %0d : instr1 = %h, addr2 = %0d : instr2 = %h", addr1, instr1, addr2, instr2);
        end
		$display("----Test completed---");		
        $finish;
    end

endmodule
