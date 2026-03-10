# =============================================================================
# tb_rgmii_rx.py
# Testbench cocotb pour rgmii_rx.sv
# Utilise cocotbext-eth RgmiiSource pour piloter l'interface RGMII
# =============================================================================

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotbext.eth import RgmiiSource, GmiiFrame, RgmiiSink
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamMonitor)

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

@cocotb.test()
async def test_preamble_detected(dut):
    cocotb.start_soon(Clock(dut.clk_125, 8, units="ns").start())
    # Instanciation du driver RGMII
    # RgmiiSource pilote : rgmii_rxc, rgmii_rxd, rgmii_rx_ctl
    rgmii_sink = RgmiiSink(dut.txd, dut.tx_ctl, dut.txc, dut.rst)
    axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk_125, dut.rst)
    dut.dest_mac = 0xABCD01234567
    dut.src_mac = 0xDEADBEEF0000
    dut.ethertype = 0x0101

    await axis_source.send(b'test data')
    rx_frame = await rgmii_sink.recv()
    print(rx_frame.data)

    await axis_source.send(bytearray([0xAE for i in range(150)]))
    rx_frame = await rgmii_sink.recv()
    print(rx_frame.data)

    await axis_source.send(bytearray([0xAE for i in range(5000)]))
    rx_frame = await rgmii_sink.recv()
    print(rx_frame.data)
   
    for _ in range(100):
        await RisingEdge(dut.txc)

    cocotb.log.info("OK so far..")