// simple RGMII reciever module
// can be simulated via cocotb by emulating the IDDR
// targets 1G ethernet applications (125MHz DDR / 4bits)
//
// BRH 02/25

module rgmii_rx (
    // PHY => RGMII
    input  logic        rst,
    input  logic        rxc,
    input  logic [3:0]  rxd,
    input  logic        rx_ctl,

    // bufged clk
    output logic        clk_125,
    input logic         clk200,

    // RX vers logique
    output logic [7:0]  rx_data,
    output logic        rx_dv,
    output logic        rx_er
);

// FOR COCOTB BEHAVIOR SIMULATION
`ifdef SIMULATION
    assign clk_125 = rxc;

    logic [3:0] rxd_rise, rxd_fall;
    logic       rxctl_rise, rxctl_fall;

    // rising edge => low nibble
    always_ff @(posedge rxc) begin
        rxd_rise   <= rxd;
        rxctl_rise <= rx_ctl;
    end

    // falling edge => high nibble
    always_ff @(negedge rxc) begin
        rxd_fall   <= rxd;
        rxctl_fall <= rx_ctl;
    end

    assign rx_data = {rxd_fall, rxd_rise};
    assign rx_dv   = rxctl_rise;
    assign rx_er   = rxctl_rise ^ rxctl_fall; // RX_ER = RX_DV XOR ctl_fall

// FOR KINTEX (KC705) synth
`else

    // we gather the clock in fabric using bufg
    BUFIO u_bufio (
        .I (rxc),
        .O (rxc_bufio)
    );

    BUFG u_bufg (
        .I (rxc),
        .O (clk_125)
    );

    logic [3:0]  rxd_delayed;
    logic        rx_ctl_delayed;

    // IDDR to capture falling and rising edges of rxd[3:0]
    logic [3:0] rxd_rise, rxd_fall;

    IDELAYCTRL u_idelayctrl (
        .REFCLK (clk200),
        .RST    (rst),
        .RDY    ()
    );

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : gen_idalye_two_rxd
            IDELAYE2 #(
                .IDELAY_TYPE           ("FIXED"),
                .IDELAY_VALUE          (0),
                .DELAY_SRC             ("IDATAIN"),
                .HIGH_PERFORMANCE_MODE ("TRUE"),
                .REFCLK_FREQUENCY      (200.0),
                .SIGNAL_PATTERN        ("DATA"),
                .CINVCTRL_SEL          ("FALSE"),
                .PIPE_SEL              ("FALSE")
            ) u_idelay_rxctl (
                .IDATAIN     (rxd[i]),
                .DATAOUT     (rxd_delayed[i]),
                .C           (1'b0),
                .CE          (1'b0),
                .INC         (1'b0),
                .LD          (1'b0),
                .LDPIPEEN    (1'b0),
                .REGRST      (1'b0),
                .CINVCTRL    (1'b0),
                .CNTVALUEIN  (5'b0),
                .CNTVALUEOUT ()
            );
        end
    endgenerate

    IDELAYE2 #(
        .IDELAY_TYPE           ("FIXED"),
        .IDELAY_VALUE          (0),
        .DELAY_SRC             ("IDATAIN"),
        .HIGH_PERFORMANCE_MODE ("TRUE"),
        .REFCLK_FREQUENCY      (200.0),
        .SIGNAL_PATTERN        ("DATA"),
        .CINVCTRL_SEL          ("FALSE"),
        .PIPE_SEL              ("FALSE")
    ) u_idelay_rxctl (
        .IDATAIN     (rx_ctl),
        .DATAOUT     (rx_ctl_delayed),
        .C           (1'b0),
        .CE          (1'b0),
        .INC         (1'b0),
        .LD          (1'b0),
        .LDPIPEEN    (1'b0),
        .REGRST      (1'b0),
        .CINVCTRL    (1'b0),
        .CNTVALUEIN  (5'b0),
        .CNTVALUEOUT ()
    );

    genvar j;
    generate
        for (j = 0; j < 4; j++) begin : gen_iddr_rxd
            IDDR #(
                .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"), // Q1 et Q2 alignés sur front montant
                .INIT_Q1      (1'b0),
                .INIT_Q2      (1'b0),
                .SRTYPE       ("SYNC")
            ) u_iddr_rxd (
                .C  (rxc_bufio),
                .CE (1'b1),
                .D  (rxd_delayed[j]),
                .R  (1'b0),
                .S  (1'b0),
                .Q1 (rxd_rise[j]),   // front montant
                .Q2 (rxd_fall[j])    // front descendant
            );
        end
    endgenerate

    // IDDR to capture ctl signal
    logic rxctl_rise, rxctl_fall;

    IDDR #(
        .DDR_CLK_EDGE ("SAME_EDGE_PIPELINED"),
        .INIT_Q1      (1'b0),
        .INIT_Q2      (1'b0),
        .SRTYPE       ("SYNC")
    ) u_iddr_rxctl (
        .C  (rxc_bufio),
        .CE (1'b1),
        .D  (rx_ctl_delayed),
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