// the role of this module is to grab the
// incommig rx data and parse it for prcessing in fabric
//
// BRH 02/2025

module ethernet_parser (
    // the rx domain 125MHz clock
    input logic clk125,
    input logic rst_n,

    // From rgmii rx
    input logic [7:0] rx_data,
    input logic rx_dv,
    input logic rx_er,

    // FRAME TYPE
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

    typedef enum logic [2:0] { 
        IDLE,
        PREAMBLE,
        DST_MAC,
        SRC_MAC,
        ETHERTYPE,
        PAYLOAD
    } eth_state;

    eth_state state, next_state;
    logic [2:0] mac_ptr;
    logic ethertype_ptr;

    // STATE MACHINE SEQ LOGIC
    always_ff @(posedge clk125) begin
        mac_ptr <= 0;
        ethertype_ptr <=0;
        if(~rst_n)begin
            state <= IDLE;
            payload_data <= 8'h00;
        end else begin
            state <= next_state;

            // MAC PTR logic
            if(state == SRC_MAC || state == DST_MAC)begin
                mac_ptr <= mac_ptr + 1;
            end

            if(mac_ptr == 5)begin
                mac_ptr <= 0;
            end

            // MAC LATCHING LOGIC
            if(state == DST_MAC)begin
                dest_mac[mac_ptr*8 +: 8] <= rx_data;
            end else if (state == SRC_MAC) begin
                src_mac[mac_ptr*8 +: 8] <= rx_data;
            end

            // ETHER TYPE Logic
            if(state == ETHERTYPE) begin
                ethertype_ptr <= ethertype_ptr + 1;
            end

            // LATCH PAYLOAD PASSTRHOUGH
            if(state == PAYLOAD) begin
                payload_data <= rx_data;
            end
        end
    end

    // ACTUAL STATE MACHINE
    always_comb begin : blockName
        next_state = state;

        case (state)
            IDLE : begin
                next_state = rx_dv ? PREAMBLE : IDLE;
            end

            PREAMBLE : begin
                next_state = (rx_data == 8'hD5) ? DST_MAC : PREAMBLE;
            end

            DST_MAC : begin
                next_state = mac_ptr == 5 ? SRC_MAC : DST_MAC;
            end 

            SRC_MAC : begin
                next_state = mac_ptr == 5 ? ETHERTYPE : SRC_MAC;
            end

            ETHERTYPE : begin
                next_state = ethertype_ptr == 1 ? PAYLOAD : ETHERTYPE;
            end

            PAYLOAD : begin
                next_state = rx_dv ? PAYLOAD : IDLE;
                if(rx_er) next_state = IDLE;
            end

            default : next_state = IDLE;
        endcase

        // Over ride all next states : if data is not valid,
        // we goto idle immediatly
        if(~rx_dv) next_state = IDLE;
    end

    // assignements
    assign payload_valid = (state == PAYLOAD);
    assign frame_start = (next_state == PAYLOAD) && (state==ETHERTYPE);
    assign frame_done = state == PAYLOAD && next_state == IDLE;
    assign frame_error = (state == PAYLOAD) && rx_er;

endmodule