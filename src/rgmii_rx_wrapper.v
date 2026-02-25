module rgmmi_rx_wrapper (
    // PHY => RGMII
    input  wire        rst, // active high reset
    input  wire        rxc,
    input  wire [3:0]  rxd,
    input  wire        rx_ctl,

    // bufged clk
    output wire        clk_125,

    // RX vers logique
    output wire [7:0]  rx_data,
    output wire        rx_dv,
    output wire        rx_er
);

    rgmii_rx rgmii_rx_inst(
        .rst(rst),
        .rxc(rxc),
        .rxd(rxd),
        .rx_ctl(rx_ctl),
        .clk_125(clk_125),
        .rx_data(rx_data),
        .rx_dv(rx_dv),
        .rx_er(rx_er)
    );
    
endmodule