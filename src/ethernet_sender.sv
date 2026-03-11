// grabs ehternet metadata as an input and sends of an axistream of datas

module ethernet_sender (
    input logic clk125,
    input logic rst_n,
    // AXIS IF
    input logic [7:0] s_axis_tdata,
    input logic s_axis_tvalid,
    output logic s_axis_tready,

    // eth metadata
    input logic [47:0] dest_mac,
    input logic [47:0] src_mac,
    input logic [15:0] ethertype,

    // to RGMII TX
    output logic [7:0] tx_data,
    output logic tx_dv,
    output logic tx_er
);

    localparam min_payload_size = 64;
    localparam max_payload_size = 1500;

    typedef enum logic [3:0] { 
        IDLE,
        ERROR,
        PREAMBLE,
        DST_MAC,
        SRC_MAC,
        ETHERTYPE,
        PAYLOAD,
        //PADDING,
        CRC,
        GAP
    } eth_tx_state;

    eth_tx_state state, next_state;
    logic [$clog2(8)-1:0] preamble_counter;
    logic [$clog2(6)-1:0] mac_counter;
    logic ethtype_counter;
    logic [$clog2(1500) -1 : 0] payload_counter;
    logic [31:0] crc_reg;
    logic [$clog2(4)-1:0] crc_send_counter;
    logic [$clog2(12)-1:0] gap_counter;

    always_ff @( posedge clk125 ) begin
        if(~rst_n)begin
            state <= IDLE;
            preamble_counter <= 0;
            mac_counter <= 0;
            ethtype_counter <= 0;
            payload_counter <= 0;
            crc_reg <= 32'hFFFFFFFF;
            crc_send_counter <= 0;
            gap_counter <= 0;
        end else begin
            state <= next_state;
            
            if(state == ERROR)begin
                state <= IDLE;
                preamble_counter <= 0;
                mac_counter <= 0;
                ethtype_counter <= 0;
                payload_counter <= 0;
                crc_reg <= 32'hFFFFFFFF;
                crc_send_counter <= 0;
                gap_counter <= 0;
            end

            if(state == IDLE) begin
                crc_reg <= 32'hFFFFFFFF;
            end

            if(state == PREAMBLE)begin
                preamble_counter <= preamble_counter + 1;
            end

            if(state == DST_MAC) begin
                mac_counter <= mac_counter + 1;
                if(mac_counter == 5) mac_counter <= 0;
            end

            if(state == SRC_MAC) begin
                mac_counter <= mac_counter + 1;
                if(mac_counter == 5) mac_counter <= 0;
            end

            if(state == ETHERTYPE) begin
                ethtype_counter <=  ethtype_counter + 1;
            end

            if(state == PAYLOAD) begin
                payload_counter <= payload_counter +1;
            end
            if(state == CRC) begin
                crc_send_counter <= crc_send_counter +1;
            end

            if(state == GAP) begin
                gap_counter <= gap_counter + 1;
            end

            // CRC COMPUTATION LOGIC
            if(state == DST_MAC)
                crc_reg <= crc32_byte(crc_reg, dest_mac[47 - mac_counter*8 -: 8]);
            if(state == SRC_MAC)
                crc_reg <= crc32_byte(crc_reg, src_mac[47 - mac_counter*8 -: 8]);
            if(state == ETHERTYPE)
                crc_reg <= crc32_byte(crc_reg, ethtype_counter ? ethertype[7:0] : ethertype[15:8]);
            if(state == PAYLOAD)
                crc_reg <= crc32_byte(crc_reg, s_axis_tvalid ? s_axis_tdata : 8'h00);
        end
    end

    always_comb begin
        // defaults
        tx_er = 0;
        tx_dv = 0;
        tx_data = 0;
        next_state = state;
        s_axis_tready = 0;

        // comb FSM logic
        case (state)
            IDLE : begin

                if(s_axis_tvalid) next_state = PREAMBLE;
            end

            ERROR : begin
                tx_er = 1;
                tx_dv = 0;
            end

            PREAMBLE : begin
                tx_er = 0;
                tx_dv = 1;
                if(preamble_counter != 7)begin
                    tx_data = 8'h55;
                end else begin
                    tx_data = 8'hD5;
                    next_state = DST_MAC;
                end
            end

            DST_MAC : begin
                tx_dv = 1;
                tx_er = 0;
                tx_data = dest_mac[47 - mac_counter*8 -: 8];

                if(mac_counter == 5) next_state = SRC_MAC;
            end

            SRC_MAC : begin
                tx_dv = 1;
                tx_er = 0;
                tx_data = src_mac[47 - mac_counter*8 -: 8];

                if(mac_counter == 5) next_state = ETHERTYPE;
            end

            ETHERTYPE : begin
                tx_dv = 1;
                tx_er = 0;
                tx_data = ethtype_counter ? ethertype[7:0] : ethertype[15:8];
                
                if(ethtype_counter == 1) next_state = PAYLOAD;
            end

            PAYLOAD : begin
                s_axis_tready = 1;
                tx_data = s_axis_tdata;
                tx_dv = 1;

                if(s_axis_tvalid == 0 && (payload_counter >= min_payload_size-1)) next_state = CRC;
                if(payload_counter == max_payload_size -1) next_state = CRC;

                // auto padding//(todo: add solid padding state but that should work just fine)
                if(s_axis_tvalid == 0) tx_data = 0;
            end

            CRC : begin
                tx_data = ~crc_reg[crc_send_counter*8 +: 8];
                tx_dv = 1;

                if(crc_send_counter == 3) next_state = GAP;
            end

            GAP : begin
                tx_dv = 0;
                tx_er = 0;
                if(gap_counter == 11) next_state = IDLE;
            end

            default : ;
        endcase

        // by default, when sending a frame, if valid drops, we enter the error state.
        if(~s_axis_tvalid && (state != IDLE) && (state != PAYLOAD) && (state != ERROR) && state != (CRC) && state != (GAP)) next_state = ERROR;
    end

endmodule


// crc compute function
function automatic [31:0] crc32_byte(
    input [31:0] crc_in,
    input [7:0]  data
);
    logic [31:0] crc;
    logic [7:0]  d;
    crc = crc_in;
    d   = data;
    for (int i = 0; i < 8; i++) begin
        if ((crc[0] ^ d[0]) == 1'b1)
            crc = (crc >> 1) ^ 32'hEDB88320;
        else
            crc = crc >> 1;
        d = d >> 1;
    end
    return crc;
endfunction