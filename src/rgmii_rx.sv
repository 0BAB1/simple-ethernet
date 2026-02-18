module rgmii_rx (
    // -------------------------------------------------------------------
    // Pins physiques RGMII (vers/depuis le PHY)
    // -------------------------------------------------------------------
    input  logic rst,                    
    input  logic        rxc,       // Horloge RX fournie par le PHY
    input  logic [3:0]  rxd,       // Données RX 4 bits
    input  logic        rx_ctl,    // RX_DV (front montant) + RX_ER^RX_DV (front descendant)

    // -------------------------------------------------------------------
    // Interface logique interne (domaine clk_125)
    // -------------------------------------------------------------------
    output logic        clk_125,         // Horloge 125 MHz récupérée du PHY (RX)

    // RX vers logique
    output logic [7:0]  rx_data,         // Octet reçu (nibble haut + nibble bas reconstitués)
    output logic        rx_dv,           // Data Valid
    output logic        rx_er            // Error
);

// =============================================================================
// SECTION RX
// =============================================================================

`ifdef SIMULATION
    // Horloge simulée = RXC direct
    assign clk_125    = rxc;

    // Capture des nibbles sur les deux fronts
    logic [3:0] rxd_rise, rxd_fall;
    logic       rxctl_rise, rxctl_fall;

    // Front montant → nibble bas (bits 3:0)
    always_ff @(posedge rxc) begin
        rxd_rise   <= rxd;
        rxctl_rise <= rx_ctl;
    end

    // Front descendant → nibble haut (bits 7:4)
    always_ff @(negedge rxc) begin
        rxd_fall   <= rxd;
        rxctl_fall <= rx_ctl;
    end

    // Reconstitution de l'octet et des signaux de contrôle
    // Note : on re-synchronise rxd_fall sur le front montant suivant
    //        pour avoir rx_data stable dans le même domaine d'horloge
    logic [3:0] rxd_fall_sync;
    logic       rxctl_fall_sync;

    always_ff @(posedge rxc) begin
        rxd_fall_sync   <= rxd_fall;
        rxctl_fall_sync <= rxctl_fall;
    end

    assign rx_data = {rxd_fall_sync, rxd_rise};   // [7:4]=fall, [3:0]=rise
    assign rx_dv   = rxctl_rise;
    assign rx_er   = rxctl_rise ^ rxctl_fall_sync; // RX_ER = RX_DV XOR ctl_fall

`else
    // -------------------------------------------------------------------------
    // MODE SYNTHÈSE : primitives Xilinx Kintex-7
    // -------------------------------------------------------------------------

    // --- Horloge RX ---
    // BUFG : buffer global d'horloge pour distribuer RXC sur tout le chip
    BUFG u_rxc_bufg (
        .I (rxc),
        .O (clk_125)
    );

    // --- IDDR pour RXD[3:0] ---
    // Q1 = front montant (nibble bas), Q2 = front descendant (nibble haut)
    logic [3:0] rxd_rise, rxd_fall;

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_iddr_rxd
            IDDR #(
                .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"), // Q1 et Q2 alignés sur front montant
                .INIT_Q1      (1'b0),
                .INIT_Q2      (1'b0),
                .SRTYPE       ("SYNC")
            ) u_iddr_rxd (
                .C  (clk_125),
                .CE (1'b1),
                .D  (rgmii_rxd[i]),
                .R  (1'b0),
                .S  (1'b0),
                .Q1 (rxd_rise[i]),   // front montant
                .Q2 (rxd_fall[i])    // front descendant
            );
        end
    endgenerate

    // --- IDDR pour RX_CTL ---
    logic rxctl_rise, rxctl_fall;

    IDDR #(
        .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
        .INIT_Q1      (1'b0),
        .INIT_Q2      (1'b0),
        .SRTYPE       ("SYNC")
    ) u_iddr_rxctl (
        .C  (clk_125),
        .CE (1'b1),
        .D  (rgmii_rx_ctl),
        .R  (1'b0),
        .S  (1'b0),
        .Q1 (rxctl_rise),
        .Q2 (rxctl_fall)
    );

    // Reconstitution
    assign rx_data = {rxd_fall, rxd_rise};
    assign rx_dv   = rxctl_rise;
    assign rx_er   = rxctl_rise ^ rxctl_fall;

`endif // SIMULATION

endmodule