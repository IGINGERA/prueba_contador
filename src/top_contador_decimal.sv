===================================================
// TOP LEVEL MODULE MODIFICADO APRA  TINY TAPE OUT 
// ============================================================
module tt_um_contador_decimal (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    wire [6:0] w_seg_cen;
    wire [6:0] w_seg_dec;
    wire [6:0] w_seg_uni;
    wire rst_net = rst_n; 

    // Instancia del sistema completo
    bloque_contador_interno u_sistema_contador (
        .reloj   (clk),
        .reset   (rst_net),
        .seg_cen (w_seg_cen),
        .seg_dec (w_seg_dec),
        .seg_uni (w_seg_uni)
    );

    // Multiplexor de displays
    reg [16:0] scan_counter;
    always @(posedge clk) begin
        if (!rst_n) scan_counter <= 0;
        else scan_counter <= scan_counter + 1;
    end

    wire [1:0] selector = scan_counter[16:15]; 
    reg [6:0] salida_segmentos;
    reg [2:0] salida_anodos; 

    always @(*) begin
        case (selector)
            2'b00: begin 
                salida_segmentos = w_seg_uni;
                salida_anodos    = 3'b110; 
            end
            2'b01: begin 
                salida_segmentos = w_seg_dec;
                salida_anodos    = 3'b101; 
            end
            2'b10: begin 
                salida_segmentos = w_seg_cen;
                salida_anodos    = 3'b011; 
            end
            default: begin 
                salida_segmentos = 7'b0000000; 
                salida_anodos    = 3'b111; 
            end
        endcase
    end

    assign uo_out[6:0]  = salida_segmentos;
    assign uo_out[7]    = 0;            
    assign uio_out[2:0] = salida_anodos; 
    assign uio_out[7:3] = 0;            
    assign uio_oe       = 8'b11111111;  
    
    wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule


// ============================================================
// LOGICA INTERNA DEL CONTADOR
// ============================================================
module bloque_contador_interno (
    input  logic reloj,   
    input  logic reset,   
    output logic [6:0] seg_cen, 
    output logic [6:0] seg_dec, 
    output logic [6:0] seg_uni  
);

    int cable_cuenta;
    int cable_c, cable_d, cable_u;

    contador_principal inst_contador (
        .reloj(reloj),
        .reset(reset),
        .cuenta_salida(cable_cuenta)
    );

    separador_matematico inst_matematicas (
        .cuenta_entrada(cable_cuenta),
        .c(cable_c),
        .d(cable_d),
        .u(cable_u)
    );

    driver_centenas  inst_disp_cen (.digito(cable_c), .seg(seg_cen));
    driver_decenas   inst_disp_dec (.digito(cable_d), .seg(seg_dec));
    driver_unidades  inst_disp_uni (.digito(cable_u), .seg(seg_uni));

endmodule   

module separador_matematico (
    input  int cuenta_entrada,
    output int c,
    output int d,
    output int u
);
    assign c = cuenta_entrada / 100;
    assign d = (cuenta_entrada % 100) / 10;
    assign u = cuenta_entrada % 10;
endmodule

module contador_principal (
    input  logic reloj,
    input  logic reset,
    output int   cuenta_salida
);
    int FRECUENCIA_FPGA     = 50000000; 
    int NUMEROS_POR_SEGUNDO = 4;    
    int LIMITE              = 5; 
    
    int contador_tiempo;
    int cuenta_interna;

    always_ff @(posedge reloj) 
        begin
        if (reset == 0)     
                begin
                    contador_tiempo <= 0;
                    cuenta_interna  <= 0;
                end 
            else 
                begin
                    if (contador_tiempo == LIMITE) 
                        begin
                            contador_tiempo <= 0;
                            if (cuenta_interna >= 255) 
                                begin
                                    cuenta_interna <= 0;
                                end 
                            else 
                                begin
                                    cuenta_interna <= cuenta_interna + 1;
                                end
                            end 
                    else 
                        begin
                            contador_tiempo <= contador_tiempo + 1;
                        end
                    end
                end
    assign cuenta_salida = cuenta_interna;
endmodule

module driver_centenas (
    input  int digito,
    output logic [6:0] seg
);
    always_comb begin
        case (digito)
            0: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=0; end
            1: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            2: begin seg[6]=1; seg[5]=1; seg[4]=0; seg[3]=1; seg[2]=1; seg[1]=0; seg[0]=1; end
            3: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=0; seg[0]=1; end
            4: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=1; seg[0]=1; end
            5: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            6: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            7: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            8: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            9: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            default: seg = 0;
        endcase
    end
endmodule

module driver_decenas (
    input  int digito,
    output logic [6:0] seg
);
    always_comb begin
        case (digito)
            0: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=0; end
            1: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            2: begin seg[6]=1; seg[5]=1; seg[4]=0; seg[3]=1; seg[2]=1; seg[1]=0; seg[0]=1; end
            3: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=0; seg[0]=1; end
            4: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=1; seg[0]=1; end
            5: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            6: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            7: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            8: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            9: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            default: seg = 0;
        endcase
    end
endmodule

module driver_unidades (
    input  int digito,
    output logic [6:0] seg
);
    always_comb begin
        case (digito)
            0: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=0; end
            1: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            2: begin seg[6]=1; seg[5]=1; seg[4]=0; seg[3]=1; seg[2]=1; seg[1]=0; seg[0]=1; end
            3: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=0; seg[0]=1; end
            4: begin seg[6]=0; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=1; seg[0]=1; end
            5: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            6: begin seg[6]=1; seg[5]=0; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            7: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=0; seg[2]=0; seg[1]=0; seg[0]=0; end
            8: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=1; seg[1]=1; seg[0]=1; end
            9: begin seg[6]=1; seg[5]=1; seg[4]=1; seg[3]=1; seg[2]=0; seg[1]=1; seg[0]=1; end
            default: seg = 0;
        endcase
    end
endmodule
