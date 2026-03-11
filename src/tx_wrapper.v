// used in vivado to wraper arround rgmii_tx and the sender
// resulting in only slave AXIS + metadata exposed on the SoC side
// and RGMII on the PHY side

// BRH 2/2025

module rx_wrapper (
    input wire        rst, // act high rst
    input wire        clk_125,
    
    // RGMII TO PHY
    output wire        txc,
    output wire [3:0]  txd,
    output wire        tx_ctl  

    // SLAVE AXI STREAM
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TDATA" *)
    input wire [7:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TVALID" *)
    input wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TREADY" *)
    output wire m_axis_tready
    //clkout
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk125_out CLK" *)
    output wire clk125_out,

    // FRAME METADATA
    input wire [15:0] ethertype,
    input wire [47:0] dest_mac,
    input wire [47:0] src_mac
);
    wire [7:0] tx_data;
    wire       tx_dv;
    wire       tx_er;

    ethernet_sender ethernet_sender_inst (
        .clk125       (clk_125),
        .rst_n        (~rst),
        .s_axis_tdata (s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .dest_mac     (dest_mac),
        .src_mac      (src_mac),
        .ethertype    (ethertype),
        .tx_data      (tx_data),
        .tx_dv        (tx_dv),
        .tx_er        (tx_er)
    );

    rgmii_tx rgmii_tx_inst (
        .clk_125 (clk_125),
        .rst     (rst),
        .tx_data (tx_data),
        .tx_dv   (tx_dv),
        .tx_er   (tx_er),
        .txc     (txc),
        .txd     (txd),
        .tx_ctl  (tx_ctl)
    );
    
endmodule