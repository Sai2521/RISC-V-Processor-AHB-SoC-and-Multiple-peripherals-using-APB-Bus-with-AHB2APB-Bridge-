# RISC-V-Processor-AHB-SoC-and-Multiple-peripherals-using-APB-Bus-with-AHB2APB-Bridge
<dr>
Multi-layer-AHB-lite
AHB-Lite Based SoC Design
📌 Overview
This project demonstrates the incremental development of an AMBA AHB-Lite based system-on-chip (SoC), starting from a single-layer AHB-Lite system, extending to a multi-layer AHB-Lite interconnect, and finally integrating a RISC-V pipelined processor as the host (master) in the multi-layer system.

The design connects to three memory-mapped peripherals (slaves):

Timer
GPIO
Register File
🚀 Design Flow
1. Single-Layer AHB-Lite System
Architecture includes one master and multiple slaves.
Master initiates read/write transactions.
Address decoding logic routes transactions to:
Timer
GPIO
Register File
2. Multi-Layer AHB-Lite System
Extended to support multiple masters with parallelism.
Key components of the interconnect:
Arbiter – resolves conflicts between masters.
Slave Interface – manages communication with slaves.
Multiplexer – routes master-to-slave signals.
Each slave instantiates its own set of interconnect blocks.
Supports parallel transactions when masters access different slaves.
3. RISC-V Integration
A RISC-V pipelined processor is integrated as Host A (Master A).
A testbench acts as Host B (Master B).
Both masters connect to the multi-layer AHB-Lite interconnect.
The RISC-V processor is customized to be compatible with the SoC:
Data memory is extended for memory-mapped peripherals.
Address mapping:
0x0000 – 0x001F → GPIO
0x0020 – 0x003F → Timer
0x0040 and above → Register File
