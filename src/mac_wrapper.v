// used in vivado to wraper arround rgmii_rx and the parder
// Takes in RGMII signals from PHY and output all the frame infos + AXI STREAM for data

// this wraps the rgmii_rx AND parser.
// That allows to use cocotb ext eth frames
// fror testing directly
//
// BRH 2/2025

module mac_wrapper (
    // PHY => RGMII
    input         rst, // act high rst
    input         rxc,
    input  [3:0]  rxd,
    input         rx_ctl,

    // FRAME DELIMITER 
    output frame_start,

    // AXI STREAM
    input tready, // unused, always assumed =1
    output tlast,
    output tvalid,
    output [7:0] tdata,

    // PARSED FRAME INFOs
    output [15:0] ethertype,
    output payload_valid,
    output [47:0] dest_mac,
    output [47:0] src_mac    
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
        .frame_last(tlast),
        .payload_data(tdata),
        .payload_valid(tvalid),
        .dest_mac(dest_mac),
        .src_mac(src_mac)
    );
    
endmodule