# Simple ethenet

Personal simple eternet 1Gbps project.

Demo based on an HOLY CORE SoC (clone HOLY_CORE_COURSE at root via this link : https://github.com/0BAB1/HOLY_CORE_COURSE.git)

Run `vivado -source ./scripts/vivado_holy_core_setup.tcl` to create demo project.

## Silence errors due to pulp platform vendore files

- you may get synth errors on lines line ``include "common_cells/registers.svh"`, just remove `common_cells/` as header are included without subfolder.
- Also copy all .svh from include/ to vendor/ to silence `cant open file blablabla.svh` error (and rerun sript or include files)
- Comment out all problematic assertions
- Now synth should pass okay

## SIDE NOTE / DISCLAIMER

The DMA core is a pain to work with. It uses AXIS and it may unassert `tvalid` (on the TX side) and `tready` (on the RX side) at any given time. Which really fucking sucks.

Note the script does not add FIFOs on its own, but I strongly suggest you add some + some logic to make them effective  buffer than handle back/front pressure effectively. (i.e they don't f---ing pass the ) `tvalid` & `tready`variations to RX/TX mac wrappers.