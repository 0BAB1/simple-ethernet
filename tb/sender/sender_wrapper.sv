// this wraps the rgmii_tx AND sender.
// That allows to use cocotb ext eth frames
// fror testing directly
//
// BRH 2/2025
module sender_wrapper (
    input  logic        clk_125,
    input  logic        rst,
    // AXIS IF
    input  logic [7:0]  s_axis_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    // eth metadata
    input  logic [47:0] dest_mac,
    input  logic [47:0] src_mac,
    input  logic [15:0] ethertype,
    // RGMII => PHY
    output logic        txc,
    output logic [3:0]  txd,
    output logic        tx_ctl  
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