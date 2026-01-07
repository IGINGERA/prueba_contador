# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Definimos el periodo del reloj (100ns -> 10 MHz)
clk_period = 100 

@cocotb.test()
async def test_counter_reset(dut):
    """Prueba para ver que el contador se resetea correctamente"""
    dut._log.info("Iniciando testbench: reset")

    # Configurando el reloj
    clock = Clock(dut.clk, clk_period, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset activo en bajo
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    # Esperamos 2 ciclos
    await ClockCycles(dut.clk, 2)

    # Liberar el reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Verificamos que sea 0 usando assert
    val = dut.uo_out.value.integer
    assert val == 0, f"El contador no se reseteo correctamente. Valor={val}"
    
    dut._log.info(" Reset funcionando correctamente")

@cocotb.test()
async def test_counter_enable_260(dut):
    """Prueba que el contador incremente hasta hacer overflow (260 ciclos)"""
    dut._log.info("Iniciando testbench: enable 260")

    # Configurando el reloj
    clock = Clock(dut.clk, clk_period, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Habilitar el contador (ui_in = 1)
    dut.ui_in.value = 1
    
    # Esperamos 260 ciclos de reloj
    await ClockCycles(dut.clk, 260)

    expected = 4
    observed = dut.uo_out.value.integer

    dut._log.info(f"Valor esperado: {expected}, observado: {observed}")

    assert observed == expected, f"Error en conteo. Esperado={expected}, Observado={observed}"
    
    dut._log.info(" Enable (conteo largo) funcionando correctamente")

@cocotb.test()
async def test_counter_disable(dut):
    """Prueba que el contador NO cambie cuando enable=0 (ui_in=0)"""
    dut._log.info("Iniciando testbench: disable")

    # Configurando el reloj
    clock = Clock(dut.clk, clk_period, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Contar unos ciclos primero
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 4)

    # Guardamos el valor actual
    prev_value = dut.uo_out.value.integer
    
    # Deshabilitar contador (ui_in = 0)
    dut.ui_in.value = 0
    
    # Esperamos 4 ciclos
    await ClockCycles(dut.clk, 4)

    observed = dut.uo_out.value.integer
    
    dut._log.info(f"Valor previo: {prev_value}, observado despues de disable: {observed}")

    assert observed == prev_value, f"Error: contador cambió con enable=0. Antes={prev_value}, Ahora={observed}"

    dut._log.info(" Disable funcionando correctamente")
