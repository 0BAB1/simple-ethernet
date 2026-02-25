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

    await rgmii_source.send(b'aaa') #616161

    for i in range(2):
        await RisingEdge(dut.rxc)

    # We skip first beat
    # as data is no well put toghther on very 1st and last beat
    # apparently that's normal and that why ethernet frames
    # have this big prembule.
    await RisingEdge(dut.rxc)

    for i in range(3):
        await RisingEdge(dut.rxc)
        assert dut.rx_data.value == 0x61 
   
    await RisingEdge(dut.rxc)

    cocotb.log.info("OK so far..")