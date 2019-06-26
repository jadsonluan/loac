/** Questão: Caixa Eletrônico
 *  Autor: Jadson Luan
 */
parameter NINSTR_BITS = 32;
parameter NBITS_TOP = 8, NREGS_TOP = 32;
module top(input  logic clk_2,
           input  logic [NBITS_TOP-1:0] SWI,
           output logic [NBITS_TOP-1:0] LED,
           output logic [NBITS_TOP-1:0] SEG,
           output logic [NINSTR_BITS-1:0] lcd_instruction,
           output logic [NBITS_TOP-1:0] lcd_registrador [0:NREGS_TOP-1],
           output logic [NBITS_TOP-1:0] lcd_pc, lcd_SrcA, lcd_SrcB,
             lcd_ALUResult, lcd_Result, lcd_WriteData, lcd_ReadData, 
           output logic lcd_MemWrite, lcd_Branch, lcd_MemtoReg, lcd_RegWrite);

  parameter estado_inicial = 0, cartao_inserido = 1, saindo_dinheiro = 2;
  parameter espera_digito1 = 3, espera_digito2 = 4, espera_digito3 = 5;
  parameter destruindo_cartao = 6, validacao = 7;

  logic [2:0] estado_atual = estado_inicial;
  logic [2:0] valor, digito1, digito2, digito3;
  logic [1:0] erros;
  logic rst, cartao;

  always_comb begin
    rst <= SWI[0];
    cartao <= SWI[1];
    valor <= SWI[6:4];
  end

  always_ff @(posedge clk_2 or posedge rst) begin
    if (rst) begin
      erros = 0;
      estado_atual <= estado_inicial;
    end 
    else begin
      unique case(estado_atual)
        estado_inicial: begin
          digito1 <= 0;
          digito2 <= 0;
          digito3 <= 0;
          if (cartao) estado_atual <= cartao_inserido;
        end

        cartao_inserido: begin
          if (cartao && valor == 0) estado_atual <= espera_digito1;
        end

        espera_digito1: begin
          if (valor != 0) begin
            digito1 <= valor;
            estado_atual <= espera_digito2;
          end
        end

        espera_digito2: begin
          if (valor != digito1) begin
            digito2 <= valor;
            estado_atual <= espera_digito3;
          end
        end

        espera_digito3: begin
          if (valor != digito2) begin
            digito3 <= valor;
            estado_atual <= validacao;
          end
        end

        validacao: begin
          if (digito1 == 1 && digito2 == 3 && digito3 == 7) estado_atual <= saindo_dinheiro;
          else begin
            erros += 1;
            if (erros >= 3) estado_atual <= destruindo_cartao;
            else estado_atual <= estado_inicial;
          end
        end
      endcase
    end
  end

  // Saída
  always_comb begin
    LED[0] <= (estado_atual == saindo_dinheiro);
    LED[1] <= (estado_atual == destruindo_cartao);
    LED[7] <= clk_2;
  end
endmodule
