# Ring King for MiSTer FPGA

The schematics are saved in `/doc`. I included both the original scans and a conversion guide containing higher-quality versions of the schematics, which are quite easy to read and understand. The board features three custom DECO chips: the VSC30, a simple chip that generates the VPOS signal; the HMC20, which is mainly a clock divider from a 12 MHz clock; and the DSPC10, which generates video signals for the rendering pipeline. Two CPUs use 6 MHz clocks (main/sprite) while the other two (sound/video) use an unknown clock, though it should be 4 MHz.

## AI

Development was accelerated by an AI-generated Verilator testbench that provided game-changing custom tooling: a full Z80 debugger with breakpoint support, memory injection, a semantic restoration system, and PCM sound export. This core is not an automatically generated AI core: AI helped significantly with the rendering pipeline, but all architectural ideas and directions are mine, based on the original documentation and schematics.
