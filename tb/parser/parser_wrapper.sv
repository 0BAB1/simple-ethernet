// this wraps the rgmii_rx AND parser.
// That allows to use cocotb ext eth frames
// fror testing directly
//
// BRH 2/2025

module parser_wrapper (
    // PHY => RGMII
    input  logic        rst, // act high rst
    input  logic        rxc,
    input  logic [3:0]  rxd,
    input  logic        rx_ctl,

    output logic [15:0] ethertype,

    // FRAME DELIMITER 
    output logic frame_start,
    output logic frame_done,
    output logic frame_error,

    // PARSED FRAME
    output logic [7:0] payload_data,
    output logic payload_valid,
    output logic [47:0] dest_mac,
    output logic [47:0] src_mac    
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
        .frame_done(frame_done),
        .frame_error(frame_error),
        .payload_data(payload_data),
        .payload_valid(payload_valid),
        .dest_mac(dest_mac),
        .src_mac(src_mac)
    );
    
endmodule