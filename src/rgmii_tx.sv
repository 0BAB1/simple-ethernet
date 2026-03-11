// simple RGMII transmitter module
// can be simulated via cocotb by emulating the ODDR
// targets 1G ethernet applications (125MHz DDR / 4bits)
//
// BRH 02/25
module rgmii_tx (
    // clock & reset
    input  logic        clk_125,
    input  logic        clk_125_90,
    input  logic        rst,

    // From TX logic
    input  logic [7:0]  tx_data,
    input  logic        tx_dv,
    input  logic        tx_er,

    // RGMII => PHY
    output logic        txc,
    output logic [3:0]  txd,
    output logic        tx_ctl
);

/* verilator lint_off MULTIDRIVEN */
`ifdef SIMULATION
    assign txc = clk_125;

    logic [3:0] txd_reg;
    logic [3:0] d_reg_2;
    logic       tx_dv_reg;   // ← pipeline tx_dv
    logic       tx_er_reg;   // ← pipeline tx_er

    always @(posedge clk_125) begin
        txd_reg   <= tx_data[3:0];
        d_reg_2   <= tx_data[7:4];
        tx_dv_reg <= tx_dv;        // ← aligné avec txd_reg
        tx_er_reg <= tx_er;
    end

    always @(negedge clk_125) begin
        txd_reg <= d_reg_2;
    end

    assign txd     = txd_reg;
    assign tx_ctl  = clk_125 ? tx_dv_reg : (tx_dv_reg ^ tx_er_reg);

`else
    // --- TXC via ODDR ---
    // On génère l'horloge TX depuis clk_125
    // D1=1 front montant, D2=0 front descendant → génère une horloge
    ODDR #(
        .DDR_CLK_EDGE ("SAME_EDGE"),
        .INIT         (1'b0),
        .SRTYPE       ("ASYNC")
    ) u_oddr_txc (
        .C  (clk_125_90),
        .CE (1'b1),
        .D1 (1'b1),
        .D2 (1'b0),
        .R  (1'b0),
        .S  (1'b0),
        .Q  (txc)
    );

    // --- TXD[3:0] via ODDR ---
    // D1 = nibble bas (front montant)
    // D2 = nibble haut (front descendant)
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_oddr_txd
            ODDR #(
                .DDR_CLK_EDGE ("SAME_EDGE"),
                .INIT         (1'b0),
                .SRTYPE       ("ASYNC")
            ) u_oddr_txd (
                .C  (clk_125),
                .CE (1'b1),
                .D1 (tx_data[i]),    // nibble bas sur front montant
                .D2 (tx_data[i+4]),  // nibble haut sur front descendant
                .R  (1'b0),
                .S  (1'b0),
                .Q  (txd[i])
            );
        end
    endgenerate

    // --- TX_CTL via ODDR ---
    // front montant  → tx_dv
    // front descendant → tx_dv XOR tx_er
    ODDR #(
        .DDR_CLK_EDGE ("SAME_EDGE"),
        .INIT         (1'b0),
        .SRTYPE       ("ASYNC")
    ) u_oddr_txctl (
        .C  (clk_125),
        .CE (1'b1),
        .D1 (tx_dv),
        .D2 (tx_dv ^ tx_er),
        .R  (1'b0),
        .S  (1'b0),
        .Q  (tx_ctl)
    );

`endif // SIMULATION

/* verilator lint_on MULTIDRIVEN */

endmodule