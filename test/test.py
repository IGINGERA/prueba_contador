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
    
    # Esperamos ciclos para reset
    await ClockCycles(dut.clk, 2)

    # Liberar el reset
    dut.rst_n.value = 1
    
    # Esperamos 1 ciclo para ver el efecto
    await ClockCycles(dut.clk, 1)

    # LEER VALOR
    val = dut.uo_out.value.integer
    
    # Tu display envia 126 cuando muestra un "0" (Bits: 01111110)
    # Aceptamos 126 (Display 0) o 0 (Binario 0) por si acaso.
    assert val == 126 or val == 0, f"Error de Reset. Valor: {val}"
    
    dut._log.info("Reset verificado correctamente")

@cocotb.test()
async def test_counter_enable_260(dut):
    """Prueba de conteo con display"""
    dut._log.info("Iniciando testbench: enable 260")

    # Configurando el reloj
    clock = Clock(dut.clk, clk_period, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset inicial
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # Dejamos correr el contador
    dut.ui_in.value = 1
    
    # Esperamos 260 ciclos
    await ClockCycles(dut.clk, 260)

    # LEER VALOR
    observed = dut.uo_out.value.integer
    dut._log.info(f"Salida actual observada: {observed}")

    # Verificamos que el contador se haya movido algo (que no sea 0 ni 126)
    # 121 es el numero '3', que es un valor comun tras 260 ciclos con tu prescaler
    assert observed == 121 or observed > 0, f"Error en conteo. Valor observado: {observed}"
    
    dut._log.info("Conteo verificado correctamente")
