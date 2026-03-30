################################################################
################################################################
############### ETHERNET CONSTRAINTS ###########################
################################################################
################################################################

################################
# FROM PHY RX
################################

# RGMII RX Data
set_property PACKAGE_PIN U30 [get_ports rxd[0]]
set_property PACKAGE_PIN U25 [get_ports rxd[1]]
set_property PACKAGE_PIN T25 [get_ports rxd[2]]
set_property PACKAGE_PIN U28 [get_ports rxd[3]]

# RGMII RX Control (RXDV)
set_property PACKAGE_PIN R28 [get_ports rx_ctl]

# rx clk
set_property PACKAGE_PIN U27 [get_ports rxc]

# I/O Standard (Bank 14 = 2.5V for RGMII)
set_property IOSTANDARD LVCMOS25 [get_ports {rxd[*] rx_ctl rxc}]

create_clock -name rxc_clk \
    -period 8.0 \
    [get_ports rxc]

# ── RX Input Delays ───────────────────────────────────────────────────────────
# PHY launches RXD and RX_CTL relative to RX_CLK edges
# Register 20.7 = 0 (default) → ±0.5ns skew

# # Rising edge captures
# set_input_delay -clock rxc_clk -max  0.5 [get_ports {rxd[*]}]
# set_input_delay -clock rxc_clk -min -0.5 [get_ports {rxd[*]}]
# set_input_delay -clock rxc_clk -max  0.5 [get_ports rx_ctl]
# set_input_delay -clock rxc_clk -min -0.5 [get_ports rx_ctl]

# # Falling edge captures (DDR)
# set_input_delay -clock rxc_clk -max  0.5 -clock_fall -add_delay [get_ports {rxd[*]}]
# set_input_delay -clock rxc_clk -min -0.5 -clock_fall -add_delay [get_ports {rxd[*]}]
# set_input_delay -clock rxc_clk -max  0.5 -clock_fall -add_delay [get_ports rx_ctl]
# set_input_delay -clock rxc_clk -min -0.5 -clock_fall -add_delay [get_ports rx_ctl]

# ── Clock Domain Crossing ─────────────────────────────────────────────────────
# rxc_clk (from PHY, BUFIO) and your fabric clock are unrelated/asynchronous
# Tell Vivado not to try to time paths crossing between them

set_clock_groups -asynchronous \
    -group [get_clocks rxc_clk] \
    -group [get_clocks clk125_design_1_holy_core_only_clk_gen_0]

################################
# TO PHY TX
################################

set_property PACKAGE_PIN N27 [get_ports txd[0]]
set_property PACKAGE_PIN N25 [get_ports txd[1]]
set_property PACKAGE_PIN M29 [get_ports txd[2]]
set_property PACKAGE_PIN L28 [get_ports txd[3]]

set_property PACKAGE_PIN M27 [get_ports tx_ctl]

set_property PACKAGE_PIN K30 [get_ports txc]

set_property IOSTANDARD LVCMOS25 [get_ports {txd[*] tx_ctl txc}]

create_generated_clock -name txc_clk \
    -source [get_pins design_1_i/tx_wrapper_0/inst/rgmii_tx_inst/u_oddr_txc/Q] \
    -divide_by 1 \
    [get_ports txc]

# Delay constraints.
# TX - rising edge captures
set_output_delay -clock txc_clk -max  1.2 [get_ports {txd[*]}]
set_output_delay -clock txc_clk -min -1.2 [get_ports {txd[*]}]
set_output_delay -clock txc_clk -max  1.2 [get_ports tx_ctl]
set_output_delay -clock txc_clk -min -1.2 [get_ports tx_ctl]

# TX - falling edge captures (DDR)
set_output_delay -clock txc_clk -max  1.2 -clock_fall -add_delay [get_ports {txd[*]}]
set_output_delay -clock txc_clk -min -1.2 -clock_fall -add_delay [get_ports {txd[*]}]
set_output_delay -clock txc_clk -max  1.2 -clock_fall -add_delay [get_ports tx_ctl]
set_output_delay -clock txc_clk -min -1.2 -clock_fall -add_delay [get_ports tx_ctl]

################################
# MISC
################################

# PHY RESETN
set_property PACKAGE_PIN L20 [get_ports PHY_resetn]
set_property IOSTANDARD LVCMOS25 [get_ports {PHY_resetn}]

################################################################
################################################################
############### HOLY CORE CONSTRAINTS ##########################
################################################################
################################################################

# main sys clock
set_property PACKAGE_PIN A12 [get_ports sys_diff_clock_p]
set_property PACKAGE_PIN A11 [get_ports sys_diff_clock_n]
set_property IOSTANDARD LVDS [get_ports {sys_diff_clock_p sys_diff_clock_n}]

set_property PACKAGE_PIN AD12 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN AD11 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD LVDS [get_ports {sys_diff_clock_clk_p sys_diff_clock_clk_n}]