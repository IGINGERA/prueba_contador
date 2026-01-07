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

    // Declaracion de wires internos
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


// ==============================================================================
// MODULO AGREGADO PARA EVITAR ERROR "EXIT CODE 2"
// Este módulo implementa la lógica interna del contador y el display.
// ==============================================================================

module sistema_contador_display (
    input  wire       reloj,
    input  wire       reset_n,
    output reg  [6:0] segmentos_out,
    output reg  [2:0] anodos_out
);

    // 1. Divisor de reloj simple para que el contador sea visible
    // (Si el reloj es 50MHz, necesitamos contar lento para verlo)
    reg [23:0] prescaler;
    wire tick;
    
    always @(posedge reloj or negedge reset_n) begin
        if (!reset_n)
            prescaler <= 0;
        else
            prescaler <= prescaler + 1;
    end
    
    // Usamos el bit alto del prescaler como "tick" para avanzar el contador
    assign tick = (prescaler == 0); 

    // 2. Contador simple de 0 a 9
    reg [3:0] cuenta;
    
    always @(posedge reloj or negedge reset_n) begin
        if (!reset_n) begin
            cuenta <= 0;
        end else if (tick) begin
            if (cuenta == 9)
                cuenta <= 0;
            else
                cuenta <= cuenta + 1;
        end
    end

    // 3. Decodificador de 7 segmentos (Cátodo Común: 1 encendido)
    // Mapeo: g f e d c b a
    always @(*) begin
        case(cuenta)
            4'd0: segmentos_out = 7'b0111111; // 0
            4'd1: segmentos_out = 7'b0000110; // 1
            4'd2: segmentos_out = 7'b1011011; // 2
            4'd3: segmentos_out = 7'b1001111; // 3
            4'd4: segmentos_out = 7'b1100110; // 4
            4'd5: segmentos_out = 7'b1101101; // 5
            4'd6: segmentos_out = 7'b1111101; // 6
            4'd7: segmentos_out = 7'b0000111; // 7
            4'd8: segmentos_out = 7'b1111111; // 8
            4'd9: segmentos_out = 7'b1101111; // 9
            default: segmentos_out = 7'b0000000;
        endcase
    end

    // 4. Control de ánodos (Activar uno fijo o rotar si tuvieras más dígitos)
    // Aquí activamos el primero (activo en bajo usualmente, o alto segun tu placa)
    // Asumiremos activo en bajo (0 enciende) para displays comunes.
    always @(*) begin
        anodos_out = 3'b110; // Enciende el primer dígito (derecha)
    end

endmodule
