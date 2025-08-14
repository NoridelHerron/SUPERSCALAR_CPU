# SUPERSCALAR_CPU

This project implements a 2-way superscalar, in-order, 5-stage pipelined RISC-V CPU built collaboratively in VHDL and Verilog.

It extends the classic 5-stage pipeline to fetch, decode, execute, and commit up to two instructions per cycle, while keeping the design intentionally simple so I could focus on mastering data hazard handling, forwarding, and advanced verification workflows. The architecture is modular and clear, making it an effective learning platform as well as a foundation for future designs.

## Key Features

- Dual-issue, in-order 5-stage pipeline — simplified for targeted learning goals
- Mixed VHDL + Verilog implementation for team flexibility and toolchain compatibility
- 4-read / 2-write register file for parallel operand access
- Refactored ALU with multi-issue capability
- Forwarding and hazard detection tuned for dual-issue execution
- Randomized verification with 10,000+ test cases
- Waveform-driven debugging for deep visibility into pipeline behavior
- Clean, modular structure — extensible toward more advanced architectures

## Project Goals

- Master data hazard detection and resolution in a superscalar pipeline
- Implement and refine forwarding logic for dual-issue execution
- Develop robust randomized testbenches for module- and system-level verification
- Gain proficiency in waveform debugging for both functional and performance analysis

  ---

  ## Status
**Completed**:
- Venkateshwarlu
    - Register file (4R / 2W) being implemented (Verilog) with testbench (completed)
    - Branch unit with testbench
- Madhu
    - Refactor Data Memory with testbench (completed)
- Nefeli
    - WB stage
 
---

## 👤 Contributors
- **Venkateshwarlu Yejella**
- **Madhu Kanithi**
- **Nefeli Metallidou**

## 👤 Author
**Noridel Herron**  
Senior in Computer Engineering – University of Missouri  
Gmail: noridel.herron@gmail.com  
Linkedn: [https://www.linkedin.com/public-profile/settings?lipi=urn%3Ali%3Apage%3Ad_flagship3_profile_self_edit_contact-info%3BXOBONUc%2FQ0aEoYfSz1c4Ow%3D%3D](https://www.linkedin.com/in/noridel-h-5a5534156/)
GitHub: [@NoridelHerron](https://github.com/NoridelHerron)

