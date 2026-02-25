// used in vivado to wraper arround rgmii_rx and the parder
// Takes in RGMII signals from PHY and output all the frame infos + AXI STREAM for data

// this wraps the rgmii_rx AND parser.
// That allows to use cocotb ext eth frames
// fror testing directly
//
// BRH 2/2025

module mac_wrapper (
    // PHY => RGMII
    input wire        rst, // act high rst
    input wire        rxc,
    input wire [3:0]  rxd,
    input wire        rx_ctl,

    // FRAME DELIMITER 
    output wire frame_start,

    // AXI STREAM
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TDATA" *)
    output wire [7:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TVALID" *)
    output wire m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TREADY" *)
    input wire m_axis_tready, // unused, always assumed =1
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 interface_axis TLAST" *)
    output wire m_axis_tlast,
    //clkout
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk125_out CLK" *)
    output wire clk125_out,

    // PARSED FRAME INFOs
    output wire [15:0] ethertype,
    output wire payload_valid,
    output wire [47:0] dest_mac,
    output wire [47:0] src_mac    
);
    wire clk125;
    wire [7:0] rx_data;
    wire rx_dv;
    wire rx_er;

    rgmii_rx rgmii_rx_inst(
        .rst(rst),
        .rxc(rxc),
        .rxd(rxd),
        .rx_ctl(rx_ctl),
        .clk_125(clk125),
        .rx_data(rx_data),
        .rx_dv(rx_dv),
        .rx_er(rx_er)
    );

    wire rst_n = ~rst;

    ethernet_parser ethernet_parser_inst(
        // the rx domain 125MHz clock
        .clk125(clk125),
        .rst_n(rst_n),
        .rx_data(rx_data),
        .rx_dv(rx_dv),
        .rx_er(rx_er),
        .ethertype(ethertype),
        .frame_start(frame_start),
        .frame_last(m_axis_tlast),
        .payload_data(m_axis_tdata),
        .payload_valid(m_axis_tvalid),
        .dest_mac(dest_mac),
        .src_mac(src_mac)
    );

    assign clk125_out = clk125;
    
endmodule