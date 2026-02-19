// the role of this module is to grab the
// incommig rx data and parse it for prcessing in fabric
//
// BRH 02/2025

module ethernet_parser (
    // the rx domain 125MHz clock
    input clk125,

    // From rgmii rx
    input logic [7:0] rx_data,
    input logic rx_dv,
    input logic rx_er,

    // FRAME TYPE
    output logic [15:0] ethertype,

    // FRAME DELIMITER 
    output logic frame_start,
    output logic frame_done,
    output logic frame_errpr,

    // PARSED FRAME
    output logic [7:0] payload_data;
    output logic payload_valid;
    output logic [47:0] dest_mac,
    output logic [47:0] src_mac
);

 enum logic {  } ethernet_states

endmodule