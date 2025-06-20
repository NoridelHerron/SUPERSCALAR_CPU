# SUPERSCALAR_CPU
This project implements a simple 2-way superscalar in-order pipelined RISC-V CPU, built collaboratively in VHDL and Verilog.

It extends the concepts of a classic 5-stage pipeline by allowing the CPU to fetch, decode, execute, and commit up to 2 instructions per cycle — increasing throughput while keeping the design modular and understandable.

The design uses a combination of VHDL and Verilog modules to support team collaboration and maintain flexibility across different toolchains.

## Key Features
- 2-way superscalar pipeline (dual-issue)
- Mixed VHDL + Verilog design (team-friendly and tool-friendly)
- 4-read / 2-write register file
- Refactored ALU with multi-issue support
- Forwarding and hazard detection for dual-issue
- Randomized verification (> 10,000 cases)
- Clean modular structure — extensible toward out-of-order
- Waveform-based debugging for education and verification

## Goals
- Learn practical superscalar CPU design
- Apply and extend concepts from previous single-issue pipeline
- Build a solid base for future out-of-order CPU
- Practice mixed VHDL + Verilog integration (real-world skill)
- Document progress for portfolio and collaboration

## Designs
### HAZARD DETECTION UNIT (HDU)
![Hazard diagram](images/Hazard_Guide.jpg)
Note: This is how I implemented the HDU to detect hazards.

The **Hazard Detection Unit (HDU)** identifies data hazards in a dual-issue superscalar pipeline. To design this module, I first created a dependency diagram to visualize potential conflicts between instructions across different pipeline stages.

#### Instruction A (first issued instruction)

For instruction A in the ID_EX stage, hazard checks are performed by comparing its source registers (rs1, rs2) against the destination registers (rd) of instructions ahead in the pipeline. The priority for forwarding or stall is:
- EX_MEM.A
- EX_MEM.B
- MEM_WB.A
- MEM_WB.B

This priority ensures the most recent results are considered first, enabling correct forwarding and reducing stalls.

#### Instruction B (second issued instruction)

Instruction B requires additional logic because it may depend on instruction A, which is issued in the same cycle. This is known as an intra-cycle dependency, and it must be checked before checking future pipeline stages. If B depends on A, and A is performing a register write, B must stall — otherwise it may read incorrect data from the register file too early.

After checking the dependency on A, the same priority logic as instruction A is applied:
- EX_MEM.A
- EX_MEM.B
- MEM_WB.A
- MEM_WB.B
  
Also, if instruction A stalls for any reason (e.g., load-use hazard), instruction B must also stall to maintain instruction pairing and alignment.

#### Load-Use Hazards

Classic load-use hazards are also detected by comparing the source registers of the instruction in ID against both instructions in the ID_EX stage. If an instruction in ID_EX is loading data that a following instruction depends on, a stall is inserted.

#### Summary

This hierarchical approach ensures:
- Correct execution across pipeline stages
- Accurate forwarding paths
- Proper handling of both inter-cycle and intra-cycle hazards
- Minimal and targeted stalling

By handling instruction B’s special case explicitly, the pipeline avoids subtle bugs caused by simultaneous issuance while preserving the performance benefits of dual-issue execution.

![Hazard diagram](images/HDU.png)
The image above demonstrates that the hazard detection unit is functioning correctly. Several dependency cases have been highlighted to illustrate how hazards are identified and handled. Additional screenshots are included to show more examples of detected hazards across different scenarios for both instruction A and B.

### ALU UNIT
I refactored both the adder and subtractor modules to make them reusable by removing flag generation from their logic. Instead, result computation and flag generation are now centralized in the ALU unit. Additionally, I introduced an enumerated type for ALU operations to improve code readability and simplify debugging. After refactoring, the adder, subtractor, and ALU unit were fully re-verified with 20,000 test cases.

### DECODER
The Decoder module is designed with a single 32-bit instruction input and a single output structured as a record type. This output aggregates all decoded fields, including opcode, function codes, register indices, and the unshifted immediate value. Resizing and alignment of the immediate field are deferred to the top-level logic within the Instruction Decode (ID) stage. It was also fully verified with 20,000 test cases.

The decoder is fully compliant with the RISC-V instruction set reference and supports all instruction formats. For verification, a dedicated testbench was developed that generates randomized 32-bit values, constrained to ensure only valid RISC-V instructions are produced.

### Control Unit
The Control Unit accepts a single input: the 7-bit opcode extracted from the instruction. Based on the opcode, it outputs a structured record containing all relevant control signals required by the datapath. Each control signal is deterministically derived from the opcode type, enabling precise configuration of the processor’s behavior for each instruction class (e.g., R-type, I-type, S-type, etc.).

The use of a record output improves clarity and modularity, making the control logic easier to extend or debug in future design iterations.

## Status
**In progress**:
- Nori
    - Architecture planning complete
    - Hazard Detection Unit with testbench
- Venkateshwarlu
    - Register file (4R / 2W) being implemented (Verilog) with testbench
    - Branch unit with testbench
- Madhu
    - Refactor Data Memory with testbench


## 👤 Authors
**Noridel Herron**  
Senior in Computer Engineering – University of Missouri  
✉️ noridel.herron@gmail.com  
GitHub: [@NoridelHerron](https://github.com/NoridelHerron)

## 👤 Contributors
**Venkateshwarlu Yejella**
**Madhu Kanithi**




