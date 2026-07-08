# ASIC Flow

Common ASIC flow scripts for synthesis, PnR, STA, ATPG, and power/droop analysis.

Current status:
- PDK setup: Nangate45
- Synthesis tool: Cadence Genus
- First target designs: PicoRV32, CV32E40P, Ibex, VeeR-EH2

Directory structure:

```text
asic_flow/
  common/
    pdk/
    syn/
    pnr/
    sta/
    atpg/
    power/
  templates/
    syn/
  docs/