# RGMII RX Data
set_property PACKAGE_PIN U30 [get_ports rxd[0]]
set_property PACKAGE_PIN U25 [get_ports rxd[1]]
set_property PACKAGE_PIN T25 [get_ports rxd[2]]
set_property PACKAGE_PIN U28 [get_ports rxd[3]]

# RGMII RX Control (RXDV)
set_property PACKAGE_PIN R28 [get_ports rx_ctl]

# rx clk
set_property PACKAGE_PIN U27 [get_ports rxc]

# PHY RESETN
set_property PACKAGE_PIN L20 [get_ports PHY_resetn]

# I/O Standard (Bank 14 = 2.5V for RGMII)
set_property IOSTANDARD LVCMOS25 [get_ports {rxd[*] rx_ctl rxc PHY_resetn}]
