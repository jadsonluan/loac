/** Prova 2019.1
 *  Autor: Jadson Luan
 *  Objetivo: implementar o sistema de controle de um elevador
 *
 *  O elevador leva pessoas do andar A para o andar B.
 *  Ele não leva pessoas de B para A. A capacidade máxima
 *  do elevador é de 2 pessoas.
 *  
 *  Quando a porta no andar A estiver aberta, pessaos podem
 *  entrar no elevador, uma a cada clock. Tem um sensor na
 *  porta que detecta a entrada de uma pessoa.
 *
 *  Quando tiverem duas pessoas dentro do elevador, a porta é
 *  fechada e o elevador vai para o andar B.
 *
 *  Quando tiver somente uma pessoa, mas ela já esperou 2 clock
 *  a porta se fecha e ela vai para o andar B.
 *
 *  Depois de 2 ciclos de clock, ele chega no andar B, a porta se
 *  abre por tantos ciclos de clock quanto tem passageiros e volta
 *  para o andar A em 2 ciclos de clock.
 *
 *  No andar A a porta se abre e começa tudo de novo.
 *
 *  Entradas: clock - 0.5Hz, aparecendo em SEG[7]
 *            reset - SWI[7]
 *            pessoa - sinalizada entrada de 1 pessoa no elevador - SWI[0]
 *
 *  Saídas: andar - (0 => Andar A, 1 => Andar B) - LED[0]
 *          porta - sinaliza que a porta está aberta - LED[1]
 *
 *  No reset, a porta deve estar aberta e o elevador deve estar no andar A e estar vazio.
 *  A entrada de uma pessoa é sinalizada na subida do clock, se o sinal ficar ativo durante
 *  duas subidas do clock, é porque entrou duas pessoas.
 *
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
  
  enum logic [1:0] {
    ANDAR_A, ANDAR_B, SUBINDO, DESCENDO
  } estado;

  logic reset, pessoa;
  logic andar = 0, porta = 0;
  logic [1:0] num_pessoas = 0, espera = 0;

  // CRIAÇÃO DO CLOCK LENTO (0.5 Hz)
  logic clock;
  logic [2:0] clock_count = 0;

  always_comb clock = clock_count[2];
  always_ff @(posedge clk_2) clock_count++;

  // Máquina de estado finito
  always_comb begin
    pessoa = SWI[0];
    reset = SWI[7];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      porta <= 0;
      andar <= 0;
      espera <= 0;
      num_pessoas <= 0;
      estado <= ANDAR_A;
    end
    else begin
      unique case(estado)
        ANDAR_A: begin
          andar <= ANDAR_A;
          porta <= 0;

          if (pessoa && num_pessoas < 2) begin
            porta <= 1;
            espera <= 0;
            num_pessoas <= num_pessoas + 1;
          end

          if (num_pessoas > 0) espera <= espera + 1;

          if (num_pessoas == 2 || (num_pessoas == 1 && espera == 2) ) begin
            espera <= 0;
            estado <= SUBINDO; 
          end
        end

        SUBINDO: begin
          espera <= espera + 1;
          porta <= 0;
          if (espera >= 2) begin
            espera <= 0;
            estado <= ANDAR_B;
          end
        end

        ANDAR_B: begin
          espera <= espera + 1;
          porta <= 1;
          if (espera == num_pessoas) begin
            espera <= 0;
            num_pessoas <= 0;
            estado <= DESCENDO;
          end
        end

        DESCENDO: begin
          espera <= espera + 1;
          porta <= 0;
          if (espera == 2) begin
            espera <= 0;
            estado <= ANDAR_A;
          end
        end
      endcase
    end
  end

  always_comb begin
    LED[0] = andar;
    LED[1] = porta;
    
    SEG[7] = clock;

    // unique case (estado)
    //   0: SEG[6:0] = 7'b0111111;
    //   1: SEG[6:0] = 7'b0000110;
    //   2: SEG[6:0] = 7'b1011011;
    //   3: SEG[6:0] = 7'b1001111;
    //   4: SEG[6:0] = 7'b1100110;
    //   5: SEG[6:0] = 7'b1101101;
    //   6: SEG[6:0] = 7'b1111101;
    // endcase
  end
endmodule
