// ============================================================
// MODULO PRINCIPAL: SISTEMA CONTADOR + MULTIPLEXOR
// ============================================================
module sistema_contador_display (
    input  logic reloj,   
    input  logic reset_n,   
    output logic [6:0] segmentos_out, 
    output logic [2:0] anodos_out  
);

    // Señales internas
    int cable_cuenta;
    int cable_c, cable_d, cable_u;
    logic [6:0] seg_c, seg_d, seg_u;

    // 1. Instancia del Contador Principal
    contador_principal inst_contador (
        .reloj(reloj), 
        .reset(reset_n), 
        .cuenta_salida(cable_cuenta)
    );

    // 2. Instancia del Separador Matemático
    separador_por_corrimientos inst_math (
        .cuenta_entrada(cable_cuenta), 
        .c(cable_c), 
        .d(cable_d), 
        .u(cable_u)
    );
    
    // 3. Conversión a 7 segmentos
    driver_centenas inst_d_cen (.digito(cable_c), .seg(seg_c));
    driver_decenas  inst_d_dec (.digito(cable_d), .seg(seg_d));
    driver_unidades inst_d_uni (.digito(cable_u), .seg(seg_u));

    // 4. Multiplexado de Salida (Barrido de Displays)
    reg [16:0] contador_barrido;
    
    always_ff @(posedge reloj) begin
        if (reset_n == 0) 
            contador_barrido <= 0;
        else 
            contador_barrido <= contador_barrido + 1;
    end
    
    // Selección de turno basado en los bits más significativos
    logic [1:0] turno;
    assign turno = contador_barrido[16:15];

    always_comb begin
        case(turno)
            2'b00: begin 
                segmentos_out = seg_u; 
                anodos_out = 3'b110; // Activa Unidades
            end
            2'b01: begin 
                segmentos_out = seg_d; 
                anodos_out = 3'b101; // Activa Decenas
            end
            2'b10: begin 
                segmentos_out = seg_c; 
                anodos_out = 3'b011; // Activa Centenas
            end
            default: begin 
                segmentos_out = 7'b0000000;    
                anodos_out = 3'b111; // Apaga todo
            end
        endcase
    end

endmodule

// ============================================================
// SUBMODULOS
// ============================================================

module separador_por_corrimientos (
    input  int cuenta_entrada,
    output int c, output int d, output int u
);
    integer i;
    reg [19:0] soporte; 
    
    // CAMBIO IMPORTANTE: Usamos always @(*) en lugar de always_comb
    // para evitar el error de "constant selects" en Icarus Verilog
    always @(*) begin
        soporte = 20'd0;
        soporte[7:0] = cuenta_entrada[7:0];
        
        for (i = 0; i < 8; i = i + 1) begin
            if (soporte[19:16] >= 5) soporte[19:16] = soporte[19:16] + 3;
            if (soporte[15:12] >= 5) soporte[15:12] = soporte[15:12] + 3;
            if (soporte[11:8]  >= 5) soporte[11:8]  = soporte[11:8]  + 3;
            soporte = soporte << 1;
        end
        
        c = soporte[19:16]; 
        d = soporte[15:12]; 
        u = soporte[11:8];
    end
endmodule

module contador_principal (
    input  logic reloj, input  logic reset, output int cuenta_salida
);
    int FRECUENCIA_FPGA     = 50000000; 
    int NUMEROS_POR_SEGUNDO = 4;    
    int LIMITE              = 5; // Valor pequeño para simulación
    int contador_tiempo; int cuenta_interna;

    always_ff @(posedge reloj) begin
        if (reset == 0) begin
            contador_tiempo <= 0; cuenta_interna  <= 0;
        end else begin
            if (contador_tiempo == LIMITE) begin
                contador_tiempo <= 0;
                if (cuenta_interna >= 255) cuenta_interna <= 0;
                else cuenta_interna <= cuenta_interna + 1;
            end else contador_tiempo <= contador_tiempo + 1;
        end
    end
    assign cuenta_salida = cuenta_interna;
endmodule

module driver_centenas (input int digito, output logic [6:0] seg);
    always_comb begin
        case (digito)
            0: seg=7'b1111110; 1: seg=7'b0110000; 2: seg=7'b1101101; 3: seg=7'b1111001;
            4: seg=7'b0110011; 5: seg=7'b1011011; 6: seg=7'b1011111; 7: seg=7'b1110000;
            8: seg=7'b1111111; 9: seg=7'b1111011; default: seg=0;
        endcase
    end
endmodule

module driver_decenas (input int digito, output logic [6:0] seg);
    always_comb begin
        case (digito)
            0: seg=7'b1111110; 1: seg=7'b0110000; 2: seg=7'b1101101; 3: seg=7'b1111001;
            4: seg=7'b0110011; 5: seg=7'b1011011; 6: seg=7'b1011111; 7: seg=7'b1110000;
            8: seg=7'b1111111; 9: seg=7'b1111011; default: seg=0;
        endcase
    end
endmodule

module driver_unidades (input int digito, output logic [6:0] seg);
    always_comb begin
        case (digito)
            0: seg=7'b1111110; 1: seg=7'b0110000; 2: seg=7'b1101101; 3: seg=7'b1111001;
            4: seg=7'b0110011; 5: seg=7'b1011011; 6: seg=7'b1011111; 7: seg=7'b1110000;
            8: seg=7'b1111111; 9: seg=7'b1111011; default: seg=0;
        endcase
    end
endmodule
