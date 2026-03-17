# Simple ethenet

Personal simple eternet 1Gbps project.

Demo based on an HOLY CORE SoC (clone HOLY_CORE_COURSE at root via this link : https://github.com/0BAB1/HOLY_CORE_COURSE.git)

Run `vivado -source ./scripts/vivado_holy_core_setup.tcl` to create demo project.

## Silence errors due to pulp platform vendore files

- you may get synth errors on lines line ``include "common_cells/registers.svh"`, just remove `common_cells/` as header are included without subfolder.
- Also copy all .svh from include/ to vendor/ to silence `cant open file blablabla.svh` error (and rerun sript or include files)
- Comment out all problematic assertions
- Now synth should pass okay