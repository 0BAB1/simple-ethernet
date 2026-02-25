// the role of this module is to grab the
// incommig rx data and parse it for prcessing in fabric
// A big buffer at the end isolates the CRC
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
    output logic frame_last,

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

    typedef struct packed {
        logic [7:0] data;
        logic       valid;
        logic       start;
        logic       last;
    } eth_payload_t;

    eth_state state, next_state;
    logic [2:0] mac_ptr;
    logic ethertype_ptr;
    eth_payload_t payload_to_buffer;

    // STATE MACHINE SEQ LOGIC
    always_ff @(posedge clk125) begin
        mac_ptr <= 0;
        ethertype_ptr <=0;
        if(~rst_n)begin
            state <= IDLE;
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
                dest_mac[47 - mac_ptr*8 -: 8] <= rx_data;
            end else if (state == SRC_MAC) begin
                src_mac[47 - mac_ptr*8 -: 8] <= rx_data;
            end

            // ETHER TYPE Logic
            if(state == ETHERTYPE) begin
                ethertype_ptr <= ethertype_ptr + 1;
            end
        end
    end

    // ACTUAL STATE MACHINE
    always_comb begin : blockName
        // default anti latch assignements
        next_state = state;
        payload_to_buffer.data = 0;

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
                // rx data passthrough
                payload_to_buffer.data = rx_data;
                next_state = rx_dv ? PAYLOAD : IDLE;
                if(rx_er) next_state = IDLE;
            end

            default : next_state = IDLE;
        endcase

        // Over ride all next states : if data is not valid,
        // we goto idle immediatly
        if(~rx_dv) next_state = IDLE;
    end

    // BUFFER logic
    assign payload_to_buffer.valid = (state == PAYLOAD);
    assign payload_to_buffer.start = (next_state == PAYLOAD) && (state==ETHERTYPE);
    assign payload_to_buffer.last = state == PAYLOAD && next_state == IDLE;

    eth_payload_t payload_buffer_s1;
    eth_payload_t payload_buffer_s2;
    eth_payload_t payload_buffer_s3;
    eth_payload_t payload_buffer_s4;
    eth_payload_t payload_buffer_s5;

    // 4 BYTES Buffer
    always_ff @( posedge clk125 ) begin : buffer
        if(~rst_n)begin
            payload_buffer_s1 <= 0;
            payload_buffer_s2 <= 0;
            payload_buffer_s3 <= 0;
            payload_buffer_s4 <= 0;
            payload_buffer_s5 <= 0;
        end else begin
            payload_buffer_s1 <= payload_to_buffer;
            payload_buffer_s2 <= payload_buffer_s1;
            payload_buffer_s3 <= payload_buffer_s2;
            payload_buffer_s4 <= payload_buffer_s3;
            payload_buffer_s5 <= payload_buffer_s4;
        end
    end

    // BUFFER OUT MUX
    // when the buffer detects frame end, it drops out CRC
    always_comb begin
        if(rx_dv && ~rx_er)begin
            payload_data = payload_buffer_s5.data;
            payload_valid = payload_buffer_s5.valid;
            frame_start = payload_buffer_s5.start;
            frame_last = payload_buffer_s5.last;
        end else begin
            payload_data = payload_buffer_s5.data;
            payload_valid = state == PAYLOAD;
            frame_start = 0;
            frame_last = payload_to_buffer.last;
        end
    end

endmodule