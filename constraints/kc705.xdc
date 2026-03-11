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

################################
# MISC
################################

# PHY RESETN
set_property PACKAGE_PIN L20 [get_ports PHY_resetn]
set_property IOSTANDARD LVCMOS25 [get_ports {PHY_resetn}]