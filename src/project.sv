/*
 * Copyright (c) 2025 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_contador_decimal (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Declacion de wires internos
    wire [6:0] w_segmentos;
    wire [2:0] w_anodos;
    
    // Instancia del sistema contador
    sistema_contador_display u_sistema (
        .reloj         (clk),
        .reset_n       (rst_n),
        .segmentos_out (w_segmentos),
        .anodos_out    (w_anodos)
    );

    // Asignacion de salidas (Mapping)
    
    // Salidas dedicadas: Bit 7 en 0, Bits 6-0 conectados a segmentos
    assign uo_out = {1'b0, w_segmentos};

    // Salidas bidireccionales: Bits 7-3 en 0, Bits 2-0 conectados a anodos
    assign uio_out = {5'b00000, w_anodos};

    // Habilitar salidas bidireccionales
    assign uio_oe  = 8'b11111111;

    // Entradas no utilizadas
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
