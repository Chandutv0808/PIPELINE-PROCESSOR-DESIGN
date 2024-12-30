module PipelinedProcessor(
    input clk, reset,
    input [31:0] instruction_in, // Instruction from instruction memory
    input [31:0] data_in,        // Data from data memory
    output reg [31:0] data_out,  // Data to be written back
    output reg [31:0] address_out // Address to access memory
);
    // Pipeline registers
    reg [31:0] IF_ID_instr, IF_ID_pc;
    reg [31:0] ID_EX_regA, ID_EX_regB, ID_EX_instr;
    reg [31:0] EX_MEM_alu_out, EX_MEM_instr;
    reg [31:0] MEM_WB_data, MEM_WB_alu_out, MEM_WB_instr;

    // Registers and memory
    reg [31:0] register_file[0:15]; // 16 general-purpose registers
    reg [31:0] pc;

    // Instruction fields
    wire [3:0] opcode = IF_ID_instr[31:28];
    wire [3:0] rs = IF_ID_instr[27:24];
    wire [3:0] rt = IF_ID_instr[23:20];
    wire [3:0] rd = IF_ID_instr[19:16];
    wire [15:0] imm = IF_ID_instr[15:0];

    // ALU control signals
    reg [31:0] alu_in1, alu_in2, alu_out;

    // Stage 1: Instruction Fetch (IF)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            IF_ID_instr <= 0;
            IF_ID_pc <= 0;
        end else begin
            IF_ID_instr <= instruction_in;
            IF_ID_pc <= pc;
            pc <= pc + 4;
        end
    end

    // Stage 2: Instruction Decode (ID)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_instr <= 0;
            ID_EX_regA <= 0;
            ID_EX_regB <= 0;
        end else begin
            ID_EX_instr <= IF_ID_instr;
            ID_EX_regA <= register_file[rs];
            ID_EX_regB <= opcode == 4'b1000 ? imm : register_file[rt]; // LOAD uses immediate
        end
    end

    // Stage 3: Execute (EX)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_alu_out <= 0;
            EX_MEM_instr <= 0;
        end else begin
            case (opcode)
                4'b0000: alu_out <= ID_EX_regA + ID_EX_regB; // ADD
                4'b0001: alu_out <= ID_EX_regA - ID_EX_regB; // SUB
                4'b0010: alu_out <= ID_EX_regA & ID_EX_regB; // AND
                4'b1000: alu_out <= ID_EX_regA + ID_EX_regB; // LOAD: Address calculation
                default: alu_out <= 0;
            endcase
            EX_MEM_alu_out <= alu_out;
            EX_MEM_instr <= ID_EX_instr;
        end
    end

    // Stage 4: Memory/Write Back (MEM/WB)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_data <= 0;
            MEM_WB_alu_out <= 0;
            MEM_WB_instr <= 0;
        end else begin
            if (opcode == 4'b1000) begin
                MEM_WB_data <= data_in; // LOAD
            end else begin
                MEM_WB_alu_out <= EX_MEM_alu_out; // Write ALU result
            end
            MEM_WB_instr <= EX_MEM_instr;
            register_file[rd] <= (opcode == 4'b1000) ? MEM_WB_data : MEM_WB_alu_out; // Write back result
        end
    end

    // Output signals
    always @(*) begin
        data_out = MEM_WB_data;
        address_out = EX_MEM_alu_out;
    end
endmodule