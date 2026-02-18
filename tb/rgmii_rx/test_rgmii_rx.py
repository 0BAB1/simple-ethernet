# =============================================================================
# tb_rgmii_rx.py
# Testbench cocotb pour rgmii_rx.sv
# Utilise cocotbext-eth RgmiiSource pour piloter l'interface RGMII
# =============================================================================

import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
from cocotbext.eth import RgmiiSource, GmiiFrame

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

@cocotb.test()
async def test_preamble_detected(dut):
    cocotb.start_soon(Clock(dut.rxc, 8, units="ns").start())
    # Instanciation du driver RGMII
    # RgmiiSource pilote : rgmii_rxc, rgmii_rxd, rgmii_rx_ctl
    rgmii_source = RgmiiSource(dut.rxd, dut.rx_ctl, dut.rxc, dut.rst)

    await rgmii_source.send(b'test data')

    await Timer(100,units="ns")
   
    cocotb.log.info("OK so far..")