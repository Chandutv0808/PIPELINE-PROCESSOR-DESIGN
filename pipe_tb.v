module tb_PipelinedProcessor;
    reg clk, reset;
    reg [31:0] instruction_in, data_in;
    wire [31:0] data_out, address_out;

    // Instantiate the processor
    PipelinedProcessor uut (
        .clk(clk),
        .reset(reset),
        .instruction_in(instruction_in),
        .data_in(data_in),
        .data_out(data_out),
        .address_out(address_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test stimulus
    initial begin
        reset = 1;
        instruction_in = 0;
        data_in = 0;

        #10 reset = 0;

        // Test ADD R1 = R2 + R3
        #10 instruction_in = {4'b0000, 4'b0010, 4'b0011, 4'b0001, 16'b0}; // ADD R1, R2, R3

        // Test SUB R4 = R5 - R6
        #10 instruction_in = {4'b0001, 4'b0101, 4'b0110, 4'b0100, 16'b0}; // SUB R4, R5, R6

        // Test AND R7 = R8 & R9
        #10 instruction_in = {4'b0010, 4'b1000, 4'b1001, 4'b0111, 16'b0}; // AND R7, R8, R9

        // Test LOAD R10 = MEM[R11 + 4]
        #10 instruction_in = {4'b1000, 4'b1011, 4'b0000, 4'b1010, 16'b0000_0000_0000_0100}; // LOAD R10, 4(R11)
        data_in = 32'hDEADBEEF; // Simulate memory returning data

        #50 $stop;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end

endmodule