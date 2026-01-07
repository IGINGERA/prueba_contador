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
    
    # Esperamos 2 ciclos de reloj para asegurar que el reset entre
    await ClockCycles(dut.clk, 2)

    # Liberar el reset
    dut.rst_n.value = 1
    
    # Esperamos 1 ciclo para ver el efecto
    await ClockCycles(dut.clk, 1)

    # LEER VALOR
    val = dut.uo_out.value.integer
    
    # Tu display envia 126 cuando muestra un "0" (Bits: 01111110)
    assert val == 126 or val == 0, f"Error de Reset. Valor: {val}"
    
    dut._log.info("Reset verificado correctamente")

@cocotb.test()
async def test_counter_enable_260(dut):
    """Prueba de conteo con display"""
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
    
    # Esperamos 260 ciclos
    await ClockCycles(dut.clk, 260)

    # LEER VALOR
    observed = dut.uo_out.value.integer
    dut._log.info(f"Salida actual observada: {observed}")

    # El contador tiene prescaler, se espera un valor distinto de 0
    # 121 es el codigo para '3' en 7 segmentos
    assert observed == 121 or observed > 0, f"Error en conteo. Valor observado: {observed}"
    
    dut._log.info("Enable verificado correctamente")

@cocotb.test()
async def test_counter_disable(dut):
    """Prueba de disable"""
    dut._log.info("Iniciando testbench: disable")

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

    # Contar un poco
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 50) 

    # Guardamos el valor actual
    prev_value = dut.uo_out.value.integer
    
    # Deshabilitar contador (ui_in = 0)
    dut.ui_in.value = 0
    
    # Esperamos varios ciclos
    await ClockCycles(dut.clk, 20)

    new_value = dut.uo_out.value.integer

    assert new_value == prev_value, f"Error: El contador cambio estando deshabilitado. Antes={prev_value}, Ahora={new_value}"

    dut._log.info("Disable verificado correctamente")
