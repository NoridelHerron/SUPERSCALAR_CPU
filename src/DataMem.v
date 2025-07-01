

// ===================================================
// Module: DATA_MEM
// Description: 32-bit data memory with read/write control
//              using a memory control signal (mem_sig)
// ===================================================
//`include "const_Types.vh"
//`include "Pipeline_Types.vh"

module DATA_MEM (
    input wire clk,                          // Clock input for synchronous operations

    input wire [1:0] mem_sig,                // Memory control signal:
                                             // 2'b00 = MEM_NONE
                                             // 2'b01 = MEM_READ
                                             // 2'b10 = MEM_WRITE

    input wire [13:0] address,                // 14-bit address (10000 locations)
    input wire [31:0] input_data,            // 32-bit data input for writing

    output reg [31:0] data_out               // 32-bit data output for reading
);

   
    // ------------ Parameters  ---------------------------------------------
  
    localparam DATA_WIDTH = 32;              // Width of each memory word
    localparam DEPTH      = 10000;            // Number of memory locations
    localparam LOG2DEPTH  = 14;              // Address width (2^14 = 16384>10000)

    // --------  Memory control signal encodings  -----------
    localparam MEM_NONE  = 2'b00;
    localparam MEM_READ  = 2'b01;
    localparam MEM_WRITE = 2'b10;
 
    // --------  Memory declaration: 1024 x 32-bit memory  -------------------------
    reg [DATA_WIDTH-1:0] mem_array [0:DEPTH-1];

 
    //----------  Memory Read/Write Logic  -----------------------------------------
    always @(posedge clk) begin
        //----- Write operation
        if (mem_sig == MEM_WRITE) begin
            mem_array[address] <= input_data;
        end

        // -----Read operation
        if (mem_sig == MEM_READ) begin
            data_out <= mem_array[address];
        end else begin
            data_out <= {DATA_WIDTH{1'b0}};  //---- Equivalent to ZERO_32BITS
        end
    end

endmodule
