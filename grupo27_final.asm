;*********************************
; * IST-UL
; * PACMAN - versão 1.0 - entrega intermédia
; * Descrição: Este programa desenha qualquer objeto 2d de pixeis com o limite de 16x32, 
; *            em qualquer posição do ecrã de dimensão 64x32 do media center, 
; *			   com apenas uma chamada de uma função.
; *			   Este programa também possuí um contador 0-100 que conta para baixo e para
; *			   cima usando 2 teclas (8 e C) do teclado, e reproduzindo um efeito sonoro 
; *			   ao clicar numa destas teclas.
; * Realizado pelo grupo 27:
; * -Luís Lopes 99791
; * -Tiago Andrade 99170
; * -Rita Gama 99166
; *********************************************************************************

; *********************************************************************************
; * Constantes
; *********************************************************************************
APAGA_ECRAS         EQU 6002H ;Endreço do media center que apaga o ecra.
DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periférico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)

LINHA4      EQU 8      ; linha a usar para o contador (4ª linha, 1000b)
LINHA3		EQU 4	   ; linha a usar para o contador (3ª linha, 1000b)
LINHA2		EQU 2	   ; linha a usar para o contador (2ª linha, 1000b)
LINHA1		EQU 1	   ; linha a usar para o contador (1ª linha, 1000b)

DEFINE_SOM 	EQU 605AH	; endereço do comando para definir o efeito sonoro
TERMINA_SOM EQU 6066H	; endereço do comando para terminar o efeito sonoro

DEFINE_LINHA    EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    EQU 6012H      ; endereço do comando para escrever um pixel

MASCARA			EQU 000FH		        ; máscara usada na conversão 
MASCARA_pacman	EQU 0000000000000001b   ; máscara usada na conversão
MASCARA_COLUNAS EQU 000FH


APAGA_AVISO 	EQU 6040H		; endereço do comando para apagar o aviso do background do media center
OBTER_CENARIO 	EQU 6042H 		; endereço do comando para obter o background do media center

COR_PIXEL_PACMAN       EQU 0FFF0H    ; cor do pixel do pacman: amarelo em ARGB 
COR_PIXEL_FANTASMA     EQU 0F0F0H    ; cor do pixel do fantasma: vermelho em ARGB
COR_TRANSPARENTE       EQU 00F00H 	
COR_GAME_OVER		   EQU 0FF00H
COR_PIXEL_CRUZ		   EQU 0FF00H
COR_PAREDE             EQU 0F54AH

; *********************************************************************************
; *                                 DADOS                                         *
; *********************************************************************************
PLACE       1000H
pilha:      TABLE 200H      ; espaço reservado para a pilha 
                            ; (200H bytes, pois são 100H words)
SP_inicial:                 ; este é o endereço (1200H) com que o SP deve ser 
                            ; inicializado. O 1.º end. de retorno será 
                            ; armazenado em 11FEH (1200H-2)
							
linha_pacman:
	WORD 0
coluna_pacman:
	WORD 0

tabela_teclas:
	WORD -1 	;(x)	cima esquerda, x--, y++			;				|0|1|2|   3
	WORD -1  	;(y)	tecla 0							;teclado----->	|4| |6|   7
														;				|8|9|A|   B
																										
	WORD 0		; cima, y++								;				 C D E    F
	WORD -1		; tecla 1
	
	WORD 1		; cima direita, x++, y++
	WORD -1		; tecla 2
	
	WORD 0000H	; tecla 3  (nao usada)
	WORD 0000H	; tecla 3
		
	WORD -1		; esquerda, x--
	WORD 0		; tecla 4
	
	WORD 0000H	; tecla 5		(nao usada)
	WORD 0000H	; tecla 5
	
	WORD 1		; direita, x++
	WORD 0		; tecla 6
	
	WORD 0000H	; tecla 7
	WORD 0000H	; tecla 7  (nao usada)
	
	WORD -1		; baixo esquerda, y--, x--
	WORD 1		; tecla 8
	
	WORD 0		; baixo, y--
	WORD 1		; tecla 9

	WORD 1		; baixo direita, y--, x++
	WORD 1		; tecla A
	
	WORD 0000H	; tecla B
	WORD 0000H	; tecla B  (nao usada)
	
	WORD 0000H	; tecla C
	WORD 0000H	; tecla C  (nao usada)
	
	WORD 0000H	; tecla D
	WORD 0000H	; tecla D  (nao usada)
	
	WORD 0000H	; tecla E
	WORD 0000H	; tecla E  (nao usada)
	
	WORD 0000H	; tecla F
	WORD 0000H	; tecla F  (nao usada)
	

evento_int:
	WORD 0
	WORD 0
	WORD 0
	WORD 0

Cruz:		
	WORD 4					;comprimento da CRUZ
	WORD 4					;altura da CRUZ, ou seja, numero de WORDs	
	WORD COR_PIXEL_CRUZ  	;cor da CRUZ
	WORD 1001b		;*******************
	WORD 0110b		;*    DESENHO 	   *
	WORD 0110b		;*	 DO OBJETO     *
	WORD 1001b		;*******************
	
Posicao_cruz_canto_superior_esquerdo:
    WORD 1        ;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
    WORD 1         ;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)

Posicao_cruz_canto_inferior_esquerdo:
    WORD 1        ;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
    WORD 27         ;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)

Posicao_cruz_canto_superior_direito:
    WORD 59        ;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
    WORD 1         ;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)

Posicao_cruz_canto_inferior_direito:
    WORD 59        ;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
    WORD 27         ;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)

Fantasma_1: 			
	WORD 4					;comprimento do FANTASMA		
	WORD 4					;altura do FANTASMA, ou seja, numero de WORDs	
	WORD COR_PIXEL_FANTASMA ;cor do FANTASMA
	WORD 0110b		;*******************
	WORD 1111b		;*    DESENHO 	   *
	WORD 1111b		;*	 DO OBJETO     *
	WORD 1001b		;*******************
Posicao_Fantasma_1:
	WORD 28		;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
	WORD 15	 	;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)
ativacao_fantasma_1:
	WORD 1
	
Fantasma_2: 			
	WORD 4					;comprimento do FANTASMA		
	WORD 4					;altura do FANTASMA, ou seja, numero de WORDs	
	WORD COR_PIXEL_FANTASMA ;cor do FANTASMA
	WORD 0110b		;*******************
	WORD 1111b		;*    DESENHO 	   *
	WORD 1111b		;*	 DO OBJETO     *
	WORD 1001b		;*******************
Posicao_Fantasma_2:
	WORD 35		;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
	WORD 15	 	;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)
ativacao_fantasma_2:
	WORD 1

Pacman:
	WORD 4					;comprimento do PACMAN	
	WORD 5					;altura do PACMAN, ou seja, numero de WORDs
	WORD COR_PIXEL_PACMAN   ;cor do PACMAN
	WORD 0110b	;*******************	
	WORD 1111b	;*     DESENHO 	   *	
	WORD 1100b  ;*       DO        *
	WORD 1111b  ;*	   OBJETO      *
	WORD 0110b  ;*******************
Posicao_Pacman:
	WORD 50   	;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
	WORD 13  	;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)

Pacman_f:
	WORD 4					;comprimento do PACMAN	
	WORD 5					;altura do PACMAN, ou seja, numero de WORDs
	WORD COR_PIXEL_PACMAN   ;cor do PACMAN
	WORD 0110b	;*******************	
	WORD 1111b	;*     DESENHO 	   *	
	WORD 1111b  ;*       DO        *
	WORD 1111b  ;*	   OBJETO      *
	WORD 0110b  ;*******************

boca_aberta_ou_fechada:
	WORD 0

math:
	WORD 0 ;x
	WORD 0 ;y
	WORD 0 ;col
math2:
	WORD 0 ;x
	WORD 0 ;y
	WORD 0 ;col
math3:
	WORD 0
	WORD 0
	WORD 0
math_parede1:
	WORD 0
	WORD 0
	WORD 0

	
Game_over:
	WORD 16					;comprimento do GAME OVER		
	WORD 6					;altura do GAME OVER, ou seja, numero de WORDs
	WORD COR_GAME_OVER   	;cor do GAME OVER
	WORD 0111000001110000b	;*******************	
	WORD 1000100010001000b	;*     DESENHO 	   *	
	WORD 1000000010001000b  ;*       DO        *
	WORD 1001100010001000b  ;*	   OBJETO      *
	WORD 1000100010001000b  ;*                 *
	WORD 0111001001110010b  ;*******************
Posicao_game_over:
	WORD 5   	;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
	WORD 5	  	;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)
	
Parede_vertical:
	WORD 15				;comprimento da PAREDE		
	WORD 8			;altura da PAREDE, ou seja, numero de WORDs
	WORD COR_PAREDE  ;cor da PAREDE
	WORD 100000010000001b	;*******************	
	WORD 100000010000001b	;*     DESENHO 	   *	
	WORD 100000010000001b 	;*       DO        *
	WORD 100000010000001b  ;*	   OBJETO      *
	WORD 100000010000001b  ;*                 *
	WORD 100000010000001b  ;*******************
	WORD 100000010000001b
	WORD 111111111111111b
Posicao_parede_vertical:
	WORD 26   	;posição x inicial da matriz no ecrã (canto superior esquerdo da matriz)
	WORD 12	  	;posição y inicial da matriz no ecrã (canto superior esquerdo da matriz)
	
	
tabela_interrupcoes:
	WORD int_0
	WORD int_1
	WORD int_2

TECLA_PREMIDA:
	WORD 0

colisoes_cruzes:
    WORD 0        ;cruz_1
    WORD 0
    WORD 0
    WORD 0

resultado_colisao_cruz1:
    WORD 0
    WORD 0
    WORD 0

resultado_colisao_cruz2:
    WORD 0
    WORD 0
    WORD 0

resultado_colisao_cruz3:
    WORD 0
    WORD 0
    WORD 0

resultado_colisao_cruz4:
    WORD 0
    WORD 0
    WORD 0
Explosao:
    WORD 5
    WORD 5
    WORD COR_GAME_OVER
    WORD 01010b
    WORD 10101b
    WORD 01010b
    WORD 10101b
    WORD 01010b
; *********************************************************************************
; *                               CÓDIGO                                          *
; *********************************************************************************
PLACE   0000H            
inicio:
    MOV  SP, SP_inicial     			; inicializa SP para a palavra a seguir à última da pilha
    
	MOV  BTE, tabela_interrupcoes      	; inicializa BTE (registo de Base da Tabela de Exceções)     
		
	;CALL clear_ecra
	MOV [APAGA_ECRAS], R1
	MOV [OBTER_CENARIO], R1
	
	MOV R6, 0
	MOV [DISPLAYS], R6
	
espera_inicio_jogo:
	CALL teclado
	
	MOV R0, [TECLA_PREMIDA]
	MOV R10, 12
	CMP R0, R10
	JNZ espera_inicio_jogo	
	;EI2 
	;CALL te
	;MOV R0, [TECLA_PREMIDA]
	;MOV R10, 12
	;CMP R0, R10
	;JNZ int_2
								; ARGUMENTOS da rotina escreve_objeto:
					;--------------------------------------
								; ARGUMENTOS da rotina escreve_objeto:
					;--------------------------------------
	MOV R10, Cruz				;Endereço do primeiro elemento da tabela que descreve o objeto CRUZ
	MOV R11, Posicao_cruz_canto_superior_esquerdo    	;Endereço do primeiro elemento da tabela que descreve a posição do objeto CRUZ
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]				;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto		;Rotina que desenha todo o objeto descrito acima.
	
	MOV R10, Cruz				;Endereço do primeiro elemento da tabela que descreve o objeto CRUZ
	MOV R11, Posicao_cruz_canto_inferior_esquerdo   	;Endereço do primeiro elemento da tabela que descreve a posição do objeto CRUZ
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]			;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto		;Rotina que desenha todo o objeto descrito acima.	

	MOV R10, Cruz				;Endereço do primeiro elemento da tabela que descreve o objeto CRUZ
	MOV R11, Posicao_cruz_canto_superior_direito    	;Endereço do primeiro elemento da tabela que descreve a posição do objeto CRUZ
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]			;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto		;Rotina que desenha todo o objeto descrito acima.
	
	MOV R10, Cruz									;Endereço do primeiro elemento da tabela que descreve o objeto CRUZ
	MOV R11, Posicao_cruz_canto_inferior_direito    ;Endereço do primeiro elemento da tabela que descreve a posição do objeto CRUZ
    MOV  R1, [R11 + 2]								;guardar posição y da tabela num registo
    MOV  R2, [R11]									;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]								;guardar cor do pixel num registo
	MOV  R4, [R10]									;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]								;guardar altura y do objeto num registo
	
	CALL desenha_objeto		;Rotina que desenha todo o objeto descrito acima.
								

	MOV R10, Pacman_f			; Endereço do primeiro elemento da tabela que descreve o objeto PACMAN
	MOV R11, Posicao_Pacman     ; Endereço do primeiro elemento da tabela que descreve a posição do objeto PACMAN
    MOV  R1, [R11 + 2]			; guardar posição y da tabela num registo
    MOV  R2, [R11]				; guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			; guardar cor do pixel num registo
	MOV  R4, [R10]				; guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			; guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
								; ARGUMENTOS da rotina escreve_objeto:
								;--------------------------------------
	MOV R10, Fantasma_1			; Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	MOV R11, Posicao_Fantasma_1 ; Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]			; guardar posição y da tabela num registo
    MOV  R2, [R11]				; guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			; guardar cor do pixel num registo
	MOV  R4, [R10]				; guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			; guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
	MOV R10, Fantasma_2			; Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	MOV R11, Posicao_Fantasma_2 ; Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]			; guardar posição y da tabela num registo
    MOV  R2, [R11]				; guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			; guardar cor do pixel num registo
	MOV  R4, [R10]				; guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			; guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
	MOV R10, Parede_vertical			; Endereço do primeiro elemento da tabela que descreve o objeto PAREDE
	MOV R11, Posicao_parede_vertical    ; Endereço do primeiro elemento da tabela que descreve a posição do objeto PAREDE
    MOV  R1, [R11 + 2]					; guardar posição y da tabela num registo
    MOV  R2, [R11]						; guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]					; guardar cor do pixel num registo
	MOV  R4, [R10]						; guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]					; guardar altura y do objeto num registo
	
	CALL desenha_objeto					; Rotina que desenha todo o objeto descrito acima.
	

	
	comeca_jogo:
	EI0			;--------------
	EI1			; INTERRUPÇÕES
	EI2         ;--------------
	EI			;--------------
	
	
ciclo:

	
	;int_0
    MOV  R2, [evento_int]         	; valor da variável que diz se houve uma interrupção com o mesmo número da coluna
    CMP  R2, 0
    JZ   sai_rotina_0_pacman     	; se não houve interrupção, vai-se embora
	MOV  R2, 0
    MOV  [evento_int], R2         	; coloca a zero o valor da variável que diz se houve uma interrupção (consome evento)
	 
	
	
	MOV R3, 0 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Parede_vertical
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_parede_vertical
	MOV R11, math3
	CALL detetor_colisoes

	MOV R6, [math3 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao1
	
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Fantasma_2
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_Fantasma_2
	MOV R11, math2
	CALL detetor_colisoes

	MOV R6, [math2 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao1
	 
	PUSH R6
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Fantasma_1
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_Fantasma_1
	MOV R11, math
	CALL detetor_colisoes

	MOV R6, [math + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao1
	JMP nao_ha_colisao1
ha_colisao1:
	MOV [APAGA_ECRAS], R6
    MOV [OBTER_CENARIO], R6
    MOV [APAGA_ECRAS], R6
    CALL desenha_explosao
	
JMP fim

nao_ha_colisao1:
	MOV R6, ativacao_fantasma_1
	MOV R10, Fantasma_1
	MOV R11, Posicao_Fantasma_1
	CALL movimento_fantasma
	
	MOV R10, Fantasma_2
	MOV R11, Posicao_Fantasma_2
	MOV R6, ativacao_fantasma_2
	CALL movimento_fantasma
	
	POP R6
sai_rotina_0_pacman:

	;int_1
     MOV  R2, [evento_int + 2]         	; valor da variável que diz se houve uma interrupção com o mesmo número da coluna
     CMP  R2, 0
     JZ   sai_rotina_1_fantasma     	; se não houve interrupção, vai-se embora
	 MOV  R2, 0
     MOV  [evento_int + 2], R2         	; coloca a zero o valor da variável que diz se houve uma interrupção (consome evento)
	 
	CALL movimento_pacman
	JMP testa_colisoes_cruzes

sai_rotina_1_fantasma:
    PUSH R0
    PUSH R1

    MOV R1, 1

    MOV R0, [colisoes_cruzes]
    CMP R0, R1
    JZ testa_cruz_2
    JNZ sair

    testa_cruz_2:
    MOV R0, [colisoes_cruzes+2]
    CMP R0, R1
    JZ testa_cruz_3
    JNZ sair

    testa_cruz_3:
    MOV R0, [colisoes_cruzes+4]
    CMP R0, R1
    JZ testa_cruz_4
    JNZ sair

    testa_cruz_4:
    MOV R0, [colisoes_cruzes+6]
    CMP R0, R1
    JZ escreve_displays_4
    JNZ sair

 
sair:
	POP R1
    POP R0
	JMP ciclo
	
	escreve_displays_4:
    PUSH R0
    MOV R0, 4
    MOV [DISPLAYS], R0
    POP R0
	JMP ha_colisao1
	fim: JMP fim
	
;************************************
;* INT_2 -está sempre a ler o teclado
;************************************
int_2:
	pausa_jogo:
	CALL teclado
	
	MOV R0, [TECLA_PREMIDA]
	MOV R10, 13
	CMP R0, R10
	JZ pausa_jogo
	
	MOV R10, 14
	CMP R0, R10
	JZ fim_jogo
	JMP comeca_jogo
	
;*********************************
;*
;*********************************
fim_jogo:
	MOV R1, 0
	MOV [APAGA_ECRAS], R1
	JMP fim_jogo
	
;************************
;* tecla 0-2, 8-A, C-E: 
teclado:
    MOV R2, TEC_LIN   	; endereço do periférico das linhas
    MOV R3, TEC_COL   	; endereço do periférico das colunas
    MOV R0, LINHA1 		; R0 é a linha inicial e todas as que sao shifted
    MOV R7, 8	

tecla_inicio_jogo:	
	MOV R1, R0             	;testa teclas (LINHAS)
    MOVB [R2], R1       	;escreve no periférico de saída o valor da linha 1
    MOVB R5, [R3]       	;lê do periférico de entrada (coluna)
    MOV R4, MASCARA_COLUNAS 
    AND R5, R4
    CMP R5, 1 
    JZ ha_tecla1

    CMP R5, 2 
    JZ ha_tecla1

    CMP R5, 4 
    JZ ha_tecla1

    MOV R6, 8

    CMP R5, R6 
    JZ ha_tecla1

    CMP R0, R7        ;chegou ao fim do teclado? se r5 = 8 significa que já testou todas as linhas 
    JZ nao_ha_tecla1
    SHL R0, 1
    JMP tecla_inicio_jogo	

	;R1 = linha (1, 2, 4 ou 8)
	;R5 = coluna (1, 2, 4 ou 8)
ha_tecla1:	
 ;registos disponiveis: R2, R3 (ja se apagou o pacman), R4, R5, R6, R7, R9, 
	;MOV R7, 1 ;incremento i++
	converte_linha1: ;input R1, output R1, converte 0001 em 1 por exemplo e 0100 em 3
	MOV R3, -1
	MOV R2, R1
	inicio_while3:
	CMP R2, 0
	JZ fim_while3
	SHR R2, 1
	ADD R3, 1
	JMP inicio_while3
	fim_while3:
	MOV R1, R3
	
	converte_coluna1: ;input R5, output R5, converte 0001 em 1 por exemplo e 0100 em 3
	MOV R3, -1
	MOV R2, R5
	inicio_while4:
	CMP R2, 0
	JZ fim_while4
	SHR R2, 1
	ADD R3, 1
	JMP inicio_while4
	fim_while4:
	MOV R5, R3
	
	converte_tecla1: ;4 * linha (R1) + coluna (R5), OUTPUT TECLA_PREMIDA
	MOV R7, 4 ;escalar 4
	MUL R1, R7;*4
	ADD R1, R5;R1 = R1 + R5
	;tecla premida em R1
	MOV [TECLA_PREMIDA], R1
	
	nao_ha_tecla1:
	RET
	
; **********************************************************************
; DESENHA_OBJETO - Rotina que desenha até uma matriz 16x32 (tamanho máximo)
; Argumentos:   R1 - posição y
;               R2 - posição x 
;               R3 - cor do pixel 
;               R4 - comprimento x do objeto
;               R5 - altura y do objeto
;               R10 - endereço de início dos dados do objeto na tabela
;
; **********************************************************************
		
desenha_objeto:
		PUSH R6 
		MOV R11, R2 				;guardar em R11 o valor da posição x, pois R2 será modificado.
		ADD R11, R4
		SUB R11, 1
		ADD R10, 6  				;encontrar na tabela o endereço no qual começam as WORDs (bits do desenho), pois está sempre a 6 de distância
		MOV R6, R10					;guardar esse endereço no registo R6
		ADD R5, R5  				;multiplicar altura y por dois, pois a altura indica o número de WORDs, e para obtermos o endereço do fim das WORDs (ultima word do desenho)
		ADD R5, R6					;guardar em R5 o tal endereço do fim das WORDs	
		
anda_linha:							;loop de fora que percorre cada linha (salta de WORD para WORD), ou seja, anda de linha em linha do objeto, e tem que ser executado y numero de vezes (altura do objeto)
		MOV R2, R11					;RESET de R2 para o valor inicial
		MOV R8, MASCARA_pacman		;RESET da máscara para 1000 0000 0000 0000b (depois de ter feito SHRs no loop interior)
		CMP R6, R5 	  				;Se chegámos ao fim das WORDs, acabámos de desenhar o objeto, e saímos 
		JZ fim_desenha_objeto   
		
		MOV R0, [R6]				;guardar em R0 o conteúdo do endreço da WORD a ser desenhada no loop interior 
		MOV R7, 0					;inicializar o contador do loop interior a 0		
	escreve_linha:  				;loop de dentro que percorre cada bit da WORD e escreve um pixel por cada 1
			CMP R7, R4 	  			;comparar R7 (contador que vai de 0 ao comprimento da WORD R4) com R4 (comprimento da WORD)
			JZ fim_escreve_linha	;saltar para o próximo ciclo do loop exterior (ou seja, próxima WORD)
			
			MOV R9, R0 				;mover a WORD em causa para R9
			AND R9, R8 				;aplicar a máscara, que analisará o bit da WORD, de acordo com a máscara presente
			JZ jump_pacman 			;no caso de ser 0, não se desenha o pixel
			CALL escreve_pixel  	;caso contrário, desenha-se o pixel
			jump_pacman:
			SHL R8, 1  				;deslocar o bit 1 da máscara para a direita, de modo a analizar o próximo bit da WORD, para ver se o temos que desenhar (1), ou não (2) 
			SUB R2, 1  				;aumentar a posição x do pixel, para se escrever o próximo (ou não) 
			ADD R7, 1  				;R7++, contador do comprimento da WORD
			JMP escreve_linha 		;continuar o loop interior
	fim_escreve_linha:				;salta para aqui se já acabou de escrever uma WORD (linha)
		ADD R6, 2					;anda 2 nos endereços da tabela de modo a passar para a próxima WORD
		ADD R1, 1					;aumentar a posição y do pixel, para se escrever a próxima WORD na linha de baixo
		JMP anda_linha				;voltar a fazer o loop exterior
		
fim_desenha_objeto:  				;salta para aqui quando acaba de escrever todo o objeto, para terminar
		POP R6
		
		RET

; **********************************************************************
; ESCREVE_PIXEL - Rotina que escreve um pixel na linha e coluna indicadas.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R3 - cor do pixel 
;
; **********************************************************************
escreve_pixel: ;funçao que desenha um pixel na posição x (R1) e y (R2), com cor (R3)
	
    MOV  [DEFINE_LINHA], R1      ; seleciona a linha
    MOV  [DEFINE_COLUNA], R2     ; seleciona a coluna
    MOV  [DEFINE_PIXEL], R3      ; altera a cor do pixel na linha e coluna selecionadas
	
	RET

; **********************************************************************
; DESENHA_PACMAN - vai buscar os dados à tabela e desenha o pacman
; **********************************************************************	
desenha_pacman:	
	PUSH R11
	PUSH R10
	PUSH R5
	PUSH R4
	PUSH R3
	PUSH R2
	PUSH R1
	PUSH R0
	
	MOV R10, Pacman				;Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	MOV R11, Posicao_Pacman     ;Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]				;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
	POP R0
	POP R1
	POP R2
	POP R3
	POP R4
	POP R5
	POP R10
	POP R11
	
	RET
;**************************************************************
;*
;**************************************************************
	desenha_pacman_f:	
	PUSH R11
	PUSH R10
	PUSH R5
	PUSH R4
	PUSH R3
	PUSH R2
	PUSH R1
	PUSH R0
	
	MOV R10, Pacman_f
	MOV R11, Posicao_Pacman     ;Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]				;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
	POP R0
	POP R1
	POP R2
	POP R3
	POP R4
	POP R5
	POP R10
	POP R11
	
	RET

; **********************************************************************
; DESENHA_FANTASMA - vai buscar os dados á tabela e desenha o fantasma
;
;		ARGS - R10: Fantasma_x
;		  	   R11: Posicao_Fantasma_x
; **********************************************************************
desenha_fantasma:	
	PUSH R11
	PUSH R10
	PUSH R6
	PUSH R5
	PUSH R4
	PUSH R3
	PUSH R2
	PUSH R1
	PUSH R0
	
	;MOV R10, Fantasma			;Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	;MOV R11, Posicao_fantasma   ;Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]			;guardar posição y da tabela num registo
    MOV  R2, [R11]				;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]			;guardar cor do pixel num registo
	MOV  R4, [R10]				;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]			;guardar altura y do objeto num registo
	
	CALL desenha_objeto			;Rotina que desenha todo o objeto descrito acima.
	
	POP R0
	POP R1
	POP R2
	POP R3
	POP R4
	POP R5
	POP R6
	POP R10
	POP R11
	
	RET
	
; **********************************************************************
; int_0 - Rotina que é executada a cada clock pulse (interrupção).
;		  Esta rotina espera que uma tecla seja premida, e se for,
;		  baseado em qual tecla foi premida, irá animar o pacman.
; **********************************************************************	
int_0:
    PUSH R1
    MOV  R1, 1               ; assinala que houve uma interrupção 0
    MOV  [evento_int], R1            ; na componente 0 da variável evento_int
    POP  R1
	
	RFE	
; **********************************************************************
; int_1 - Rotina que é executada a cada clock pulse (interrupção).
;			Esta rotina faz movimentar o fantasma de acordo
;			com a posição do pacman (perseguição).
; **********************************************************************
int_1:
    PUSH R1
    MOV  R1, 1               ; assinala que houve uma interrupção 0
    MOV  [evento_int + 2], R1          ; na componente 0 da variável evento_int
    POP  R1
	
	RFE
; **********************************************************************
; movimento_fantasma - 
;						Esta rotina faz movimentar o fantasma de acordo
;						com a posição do pacman (perseguição).
;  ARGS - R10: Fantasma_x
;		  R11: Posicao_Fantasma_x
;		  R6: ativacao do fantasma
; **********************************************************************	
movimento_fantasma:
	
	;MOV R10, Fantasma_1			;Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	PUSH R11
	MOV R11, Posicao_Pacman   	;para aceder à posição do pacman 
	MOV R2, [R11]				;R5 = x pacman
	MOV R3, [R11 + 2]   		;R6 = y pacman
	POP R11
	;MOV R11, Posicao_Fantasma_1   ;para aceder à posição do fantasma
	MOV R0, [R11]				;R7 = x fantasma
	MOV R1, [R11 + 2]			;R9 = y fantasma
	
	 MOV  R4, COR_TRANSPARENTE
     MOV  [R10 + 4], R4   		;para apagar a barra (cor transparente)
	 
	 ;MOV R10, Fantasma_1
	 ;MOV R11, Posicao_Fantasma_1
     CALL desenha_fantasma      ;apaga o fantasma do ecra

escreve_fantasma: 	;registos disponiveis: R2, R3 (ja se apagou o pacman), R4, R5, R6, R7, R9, 
	MOV R4, tabela_teclas	

;-------------------------------------------------------------
;COMPARAR POSIÇÕES PACMAN E FANTASMA
	
	CMP R0, R2 		;compara os xs da posição do pacman e do fantasma
	JZ x_igual 		;movimento na vertical
	
	CMP R1, R3		;compara os ys da posição do pacman e do fantasma
	JZ y_igual    	;movimento na horizontal
	
	CMP R0, R2
	JP x_fantasma_menor
		
	CMP R0, R2	
	JN x_fantasma_maior
	
	JMP para_movimento

y_igual: ;comparar: para decidir lado esquerdo(para trás) ou lado direito(para a frente)
	CMP R0, R2
	JZ para_movimento	
	
	CMP R0, R2 			;Fx e Px
	JP anda_esquerda 	; <=> a andar para trás
	JMP anda_direita 	; <=> a andar para a frente 
	
x_igual: ;comparar: para decidir se anda para cima ou para baixos
	CMP R1, R3
	JZ para_movimento	
	
	CMP R1, R3 
	JP anda_cima 		; <=> a andar para cima
	JMP anda_baixo 		; <=> a andar para baixo 

x_fantasma_maior:
	MOV R4, 1
	CMP R1, R3 ;Fy e Py
	JP y_menor 
		
	CMP R1, R3 ;Fy e Py
	JN y_maior 

x_fantasma_menor:
	MOV R4, -1
	CMP R1, R3 ;Fy e Py
	JP y_menor
		
	CMP R1, R3	;Fy e Py
	JN y_maior
	
y_menor:
	MOV R5, -1
	JMP para_movimento
y_maior:
	MOV R5, 1
	JMP para_movimento
	
;-----------------------------------------------
anda_esquerda:  ;x-- y=
	 MOV R4, -1 ;decrementa pos x
	 MOV R5, 0 	;mantém pos y
	 JMP para_movimento
;-----------------------------------------------
anda_direita:  	;x-- y=
	 MOV R4, 1 	;incrementa pos x
	 MOV R5, 0 	;mantém pos y
	 JMP para_movimento
;-----------------------------------------------
anda_cima:  	;x-- y=
	 MOV R4, 0 	;mantém pos x
	 MOV R5, -1 ;decrementa pos y
	 JMP para_movimento
;-----------------------------------------------
anda_baixo:  	;x-- y=
	 MOV R4, 0 	;mantém pos x
	 MOV R5, 1 	;incrementa pos y
;-----------------------------------------------


para_movimento:
	


	
	
	MOV R2, Parede_vertical
	MOV R6, Posicao_parede_vertical
	CALL desvio_paredes
	
	
	
	 ;MOV R11, Posicao_Fantasma_1
	 ADD R0, R4 ;adiconar incremento antes de atualizar pos x
	 ADD R1, R5 ;adiconar incremento antes de atualizar pos y
	 MOV [R11], R0
	 MOV [R11 + 2], R1
	 
	 ;MOV R10, Fantasma_1
	 MOV  R4, COR_PIXEL_FANTASMA
     MOV  [R10 + 4], R4
	 ;MOV R11, Posicao_Fantasma_1
	 CALL desenha_fantasma
nao_desenha: 

	MOV R4, 0
	MOV R5, 0
	;POP R7
	RET

;**************************************************************************
;* MOVIMENTO_PACMAN
;**************************************************************************

movimento_pacman:
    MOV R2, TEC_LIN   	; endereço do periférico das linhas
    MOV R3, TEC_COL   	; endereço do periférico das colunas
    MOV R0, LINHA1 		; R0 é a linha inicial e todas as que sao shifted
    MOV R7, 8

;* tecla 0-2, 8-A, C-E: 
tecla:
    MOV R1, R0             	;testa teclas (LINHAS)
    MOVB [R2], R1       	;escreve no periférico de saída o valor da linha 1
    MOVB R5, [R3]       	;lê do periférico de entrada (coluna)
    MOV R4, MASCARA_COLUNAS 
    AND R5, R4
    CMP R5, 1 
    JZ ha_tecla

    CMP R5, 2 
    JZ ha_tecla

    CMP R5, 4 
    JZ ha_tecla

    MOV R6, 8

    CMP R5, R6 
    JZ ha_tecla

    CMP R0, R7        ;chegou ao fim do teclado? se r5 = 8 significa que já testou todas as linhas 
    JZ nao_ha_tecla
    SHL R0, 1
    JMP tecla 

	;R1 = linha (1, 2, 4 ou 8)
	;R5 = coluna (1, 2, 4 ou 8)
ha_tecla:	
	anima_pacman:
	MOV R10, Pacman_f				; Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
	MOV R11, Posicao_Pacman     ; Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
	
    MOV  R2, [R11]   			; posicao x do pacman está
    MOV  R3, [R11 + 2]   		; posicao y em que o pacman está
	MOV  R4, COR_TRANSPARENTE
    MOV  [R10 + 4], R4   		; para apagar a barra (cor transparente)
    CALL desenha_pacman_f       	; apaga o pacman do ecra

escreve_pacman: ;registos disponiveis: R2, R3 (ja se apagou o pacman), R4, R5, R6, R7, R9, 
	MOV R4, tabela_teclas
	;MOV R7, 1 ;incremento i++
	converte_linha: ;input R1, output R1, converte 0001 em 1 por exemplo e 0100 em 3
	MOV R3, -1
	MOV R2, R1
	inicio_while1:
	CMP R2, 0
	JZ fim_while1
	SHR R2, 1
	ADD R3, 1
	JMP inicio_while1
	fim_while1:
	MOV R1, R3
	
	converte_coluna: ;input R5, output R5, converte 0001 em 1 por exemplo e 0100 em 3
	MOV R3, -1
	MOV R2, R5
	inicio_while2:
	CMP R2, 0
	JZ fim_while2
	SHR R2, 1
	ADD R3, 1
	JMP inicio_while2
	fim_while2:
	MOV R5, R3
	
	converte_tecla: ;4 * linha (R1) + coluna (R5), OUTPUT R1
	MOV R7, 4 ;escalar 4
	MUL R1, R7;*4
	ADD R1, R5;R1 = R1 + R5
	;tecla premida em R1
	
	MOV R11, Posicao_Pacman     ;Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
	MOV R4, tabela_teclas
	MUL R1, R7 ;*4
	ADD R4, R1
	MOV R7, [R11]
	MOV R9, [R11 + 2]
	MOV R2, [R4] ;R2 contem o incremento x		R4 contem o endreco da tabela_teclas mais o endreco necessario para chegar á tecla premida (+R1)
	MOV R3, [R4 + 2] ;R3 contem o incremento y
	


	
	ADD R9, R3 ;incrementa  pos y
	ADD R7, R2 ;incrementa  pos x
	
	
	
	CMP R7, 0
	JGT nao_passou_a_parede
	MOV R7, 0
	nao_passou_a_parede:
	CMP R9, 0
	JGT nao_passou_a_parede1
	MOV R9, 0
	nao_passou_a_parede1:
	
	PUSH R4
	MOV R4, 60
	CMP R7, R4
	JLT nao_passou_a_parede2
	MOV R7, 60
	nao_passou_a_parede2:
	MOV R4, 27
	CMP R9, R4
	JLT nao_passou_a_parede3
	MOV R9, 27
	nao_passou_a_parede3:
	
	POP R4
	
	
	MOV [R11], R7
	MOV [R11 + 2], R9
	
	PUSH R2
	MOV R2, 2
	MOV R6, [boca_aberta_ou_fechada]
	;MOV [DISPLAYS], R6
	MOD R6, R2
	POP R2
	CMP R6, 0
	JZ boca_aberta
	
	boca_fechada:
	MOV R10, Pacman_f
	MOV  R4, COR_PIXEL_PACMAN
	MOV  [R10 + 4], R4   ; para desenhar pacman a amarelo
	CALL desenha_pacman_f
	JMP continua
	
	boca_aberta:
	MOV R10, Pacman		
	MOV  R4, COR_PIXEL_PACMAN
	MOV  [R10 + 4], R4   ; para desenhar pacman a amarelo
	CALL desenha_pacman
	
	continua:
	ADD R6, 1
	MOV [boca_aberta_ou_fechada], R6
	
nao_ha_tecla:
	RET	
; **********************************************************************
; detetor_colisoes - Rotina que escreve um pixel na linha e coluna indicadas.
; Argumentos:   	  R3: profundidade da colisão
;					  R7: objeto maior 
;					  R8: objeto menor
;					  R9: posicao do objeto maior
; 					  R10: posicao do objeto menor
;					  R11: endereço de memoria que guarda o OUTPUT com espaço para 3 words (se houve colisao em x e/ou y, e se houve colisao dos objetos)
;               
;  Retorna 1 (há colisao) ou 0 (nao há colisao) em [R11] e [R11 + 2], em x e em y respetivamente.           
;  Retorna em [R11 + 4] o valor da colisao de objetos.
;(ler manual de utilizador para perceber a matematica.)
; **********************************************************************
;args: R3: 1/0 (colisao de toque ou colisao de 1 quadricula de sobreposicao) R7: pacman, R8: fantasma, R9: posicao_pacman, R10: posicao_fantasma, R11: math
detetor_colisoes:
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R6
	
	
	MOV R6, 0			;RESET dos valores da colisão para 0
	MOV [R11], R6   
	
	MOV R1, [R7] 		;comprimento x pacman (compBx)
	MOV R0, [R9]		;posicao x pacman (Bx)

	ADD R0, R1 			;(Bx + compBx)

	MOV R1, [R8]		;comp x fantasma (compbx)
	MOV R2, [R10]		;pos x fantasma	 (bx)	
	
	CMP R0, R2 			;Se Bx < bx, passamos ao segundo caso de colisao (bloco grande a vir por cima)
	JLT se_Bx_menor_bx
	ADD R1, R2  		;(bx + compbx)
						;R0 = (Bx + compBx) e R1 = (bx + compbx)
	SUB R0, R1 			;d = (Bx + compBx) - (bx + compbx)
	JMP analiza_inequacao_colisao_x ;ja temos o d, agora é ver se ha colisao em x
	
se_Bx_menor_bx:
	MOV R1, [R9]		;pos x pacman (Bx)
	MOV R0, [R10]		;pos x fantasma	 (bx)	
	
	SUB R0, R1 			;d = bx - Bx
						;ja temos o d, agora é ver se ha colisao
	
analiza_inequacao_colisao_x: ;se a inequação d <= d + 1 for verdadeira, existe colisão em x
	MOV R2, [R7] 		;comprimento x pacman (compBx)
	
	SUB R2, R0 			;i = compBx - d
	MOV R1, R2 			;R1 = i (R0 = d)
	ADD R1, R0 			;R1 = d + i
	SUB R1, R3 			;argumento de tipo de colisao (subtrair a intrusão no lado direito da inequação, de modo a detetar uma colisão mais profunda ou menos profunda)
	CMP R0, R1
	JGT nao_ha_colisao_x;se d <= d + i é falso, nao ha colisao ou seja se d > d + i é verdadeiro
	MOV R6, 1 
	MOV [R11], R6   	;guardar se houve colisão em x (1) ou não houve colisão em x (0) numa variável (argumento da função R11)
	
nao_ha_colisao_x: 		;havendo ou não colisão em x, continuamos para ver em y
	POP R6
	POP R4
	POP R3
	POP R2
	POP R1
	POP R0
	
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R6
	
	MOV R6, 0				;RESET do valor da colisão para 0
	MOV [R11 + 2], R6   
	
	MOV R1, [R7 + 2] 		;comprimento y pacman (compBy)
	MOV R0, [R9 + 2]		;posição y pacman (By)

	ADD R0, R1 				;(Bx + compBx)

	MOV R1, [R8 + 2]		;comprimento y fantasma (compby)
	MOV R2, [R10 + 2]		;posição y fantasma	 (by)	
	
	CMP R0, R2 				;Se By < by, passamos ao segundo caso de colisao (bloco grande a vir pela direita)
	JLT se_By_menor_by
	ADD R1, R2  			;(by + compby)
							;R0 = (By + compBy) e R1 = (by + compby)
	SUB R0, R1 				;d = (By + compBy) - (by + compby)
	JMP analiza_inequacao_colisao_y ;ja temos o d, agora é ver se ha colisao em y
	
se_By_menor_by:
	MOV R1, [R9 + 2]		;pos y pacman (By)
	MOV R0, [R10 + 2]		;pos y fantasma	 (by)	
	
	SUB R0, R1 				;d = by - By
							;ja temos o d, agora é ver se ha colisao em y
	
analiza_inequacao_colisao_y:
	MOV R2, [R7 + 2] 		;comprimento y pacman (compBy)
	
	SUB R2, R0 				;i = compBy - d
	MOV R1, R2 				;i = R1 (d = R0)
	ADD R1, R0
	SUB R1, R3 				;argumento de tipo de colisao (subtrair a intrusão no lado direito da inequação, de modo a detetar uma colisão mais profunda ou menos profunda)
	CMP R0, R1
	JGT nao_ha_colisao_y 	;se d <= d + i é falso, nao ha colisao ou seja se d > d + i é verdadeiro
	MOV R6, 1 
	MOV [R11 + 2], R6       ;guardar se houve colisão em y (1) ou não houve colisão em y (0) numa variável (argumento da função R11 + 2)
	
nao_ha_colisao_y:
	POP R6
	POP R3
	POP R2
	POP R1
	POP R0
	
	PUSH R2
	PUSH R6
	
	MOV R6, [R11]   		;ver se há colisão em x(se em [R11] está 1)
	CMP R6, 1				
	JZ ha_colisao_x
	JMP nao_ha_colisao_dos_objetos
ha_colisao_x:
	MOV R6, [R11 + 2]   	;ver se há colisão em y(se em [R11 + 2] está 1)
	CMP R6, 1
	JZ ha_colisao_y			;se não houver colisao em x e y, nao há colisao dos objetos
	PUSH R7
	MOV R7, 0				
	MOV [R11 + 4], R7		;escrever 0 no OUTPUT (nao houve colisao)
	POP R7
	JMP nao_ha_colisao_dos_objetos
ha_colisao_y:				;se houver colisao em x e y, ha colisao dos objetos.
	PUSH R7
	MOV R7, 1
	MOV [R11 + 4], R7		;escrever 1 no OUTPUT (houve colisao)
    POP R7
nao_ha_colisao_dos_objetos:
	POP R6
	POP R2

	RET
	
	
;input:	R4, R5
;args:   parade_X (R2)
;		 posicao parede_x (R6)
;		R10 fantasma
;		R11 posicao_fantasma
; OUTPUTS: R4 e R5	
desvio_paredes:
	 PUSH R7
	 PUSH R0
	 PUSH R10
	 PUSH R11
	 ADD R0, R4 ;adiconar incremento antes de atualizar pos x
	 ;MOV R11, Posicao_Fantasma_1
	 MOV [R11], R0
	 ;MOV [R11 + 2], R1
	 MOV R3, 1 ;1 quadricula de intrusao
	 MOV R7, R2;Parede_vertical
	 MOV R8, R10 ;Fantasma_X
	 MOV R9, R6   ;Posicao_parede_vertical
	 MOV R10, R11 ;Posicao_Fantasma_x
	 MOV R11, math_parede1
	 PUSH R4
	 MOV R4, 0
	 MOV [R11], R4
	 MOV [R11+2], R4
	 MOV [R11+4], R4
	 POP R4
	 CALL detetor_colisoes
	 
	
	 POP R11		
	 POP R10
	 POP R0
	 POP R7
	 
	 MOV R9, math_parede1
	 MOV R7, [R9 + 4]
	 CMP R7, 1
	 JZ vai_colidir_em_x
	 JMP preve_col_y
vai_colidir_em_x:
	 CMP R5, 0
	 JNZ djamp1
	 ADD R5, R4
	 MOV R4, 0
	 djamp1:
	 MOV R4, 0
	 JMP fim_previsoes
preve_col_y:
	 
	 ;PUSH R7
	 PUSH R1
	 PUSH R10
	 PUSH R11
	 ADD R1, R5 ;adiconar incremento antes de atualizar pos x
	 ;MOV R11, Posicao_Fantasma_1
	 MOV [R11 + 2], R1
	 MOV R3, 1 ;1 quadricula de intrusao
	 MOV R7, R2;Parede_vertical
	 MOV R8, R10 ;Fantasma_X
	 MOV R9, R6;Posicao_parede_vertical
	 MOV R10, R11 ;Posicao_Fantasma_x
	 MOV R11, math_parede1
	 PUSH R4
	 MOV R4, 0
	 MOV [R11], R4
	 MOV [R11+2], R4
	 MOV [R11+4], R4
	 POP R4
	 CALL detetor_colisoes
	 
	 POP R11
	 POP R10
	 POP R1
	 ;POP R7
	 
	 MOV R9, math_parede1
	 MOV R7, [R9 + 4]
	 CMP R7, 1
	 JZ vai_colidir_em_y
	 JMP fim_previsoes
vai_colidir_em_y:
	 CMP R4, 0
	 JNZ djamp2
	 ADD R4, R5
	 MOV R5, 0
	 djamp2:
	 MOV R5, 0
	 JMP fim_previsoes
	
	 
fim_previsoes:	 
	 ;JMP desvio
	 RET
	 






;******************************************************
;* TESTA_COLISOES_CRUZES -
;******************************************************
testa_colisoes_cruzes:
;-------------------------------------------------
;testa colisão com cruz do canto superior esquerdo
cruz_1:
	PUSH R6
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Cruz
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_cruz_canto_superior_esquerdo
	MOV R11, resultado_colisao_cruz1
	CALL detetor_colisoes
	
	MOV R6, [resultado_colisao_cruz1 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao2
	JMP nao_ha_colisao2
ha_colisao2:
	PUSH R6
	MOV R6, 0
	MOV R5, [colisoes_cruzes]
	CMP R5, R6
	JGT nao_incrementa1
	POP R6
	
incrementa1:
	ADD R5, 1
	MOV [colisoes_cruzes], R5
	MOV [DISPLAYS], R5
	POP R6

nao_incrementa1:
	
fim_over1:
	POP R6 
	JMP cruz_2

nao_ha_colisao2:	
	POP R6


;------------------------------------------	
	;testa colisão com cruz do canto inferior esquerdo
cruz_2:
	PUSH R6
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Cruz
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_cruz_canto_inferior_esquerdo
	MOV R11, resultado_colisao_cruz2
	CALL detetor_colisoes
;------------------------------------	
	MOV R6, [resultado_colisao_cruz2 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao3
	JMP nao_ha_colisao3
ha_colisao3:
	PUSH R6
	MOV R6, 0
	MOV R5, [colisoes_cruzes+2]
	CMP R5, R6
	JGT nao_incrementa2
	POP R6
	
incrementa2:
	ADD R5, 1
	MOV [colisoes_cruzes+2], R5
	MOV [DISPLAYS], R5
	POP R6

nao_incrementa2:
	
fim_over2: 
	POP R6
	JMP cruz_3

nao_ha_colisao3:	
	POP R6
	
;---------------------------------------------------	
	;testa colisão com cruz do canto superior direito
cruz_3:
	PUSH R6
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Cruz
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_cruz_canto_superior_direito
	MOV R11, resultado_colisao_cruz3
	CALL detetor_colisoes
	
	
	MOV R6, [resultado_colisao_cruz3 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao4
	JMP nao_ha_colisao4
ha_colisao4:
	PUSH R6
	MOV R6, 0
	MOV R5, [colisoes_cruzes+4]
	CMP R5, R6
	JGT nao_incrementa3
	POP R6
	
incrementa3:
	ADD R5, 1
	MOV [colisoes_cruzes+4], R5
	MOV [DISPLAYS], R5
	POP R6

nao_incrementa3:
	
fim_over3: 
	POP R6
	JMP cruz_4
	
nao_ha_colisao4:	
	POP R6
	
;----------------------------------------------------
	;testa colisão com cruz do canto inferior direito
cruz_4:
	PUSH R6
	MOV R3, 1 				;1 quadricula de intrusao
	MOV R7, Pacman
	MOV R8, Cruz
	MOV R9, Posicao_Pacman
	MOV R10, Posicao_cruz_canto_inferior_direito
	MOV R11, resultado_colisao_cruz4
	CALL detetor_colisoes
	
;----------------------------------------	
	MOV R6, [resultado_colisao_cruz4 + 4]   		;ver se há colisão (se em math está 1)
	CMP R6, 1
	JZ ha_colisao5
	JMP nao_ha_colisao5
ha_colisao5:
	PUSH R6
	MOV R6, 0
	MOV R5, [colisoes_cruzes+6]
	CMP R5, R6
	JGT nao_incrementa4
	POP R6
	
incrementa4:
	ADD R5, 1
	MOV [colisoes_cruzes+6], R5
	MOV [DISPLAYS], R5
	POP R6

nao_incrementa4:
	

nao_ha_colisao5:	
	POP R6
	JMP sai_rotina_1_fantasma
	
	
; **
; DESENHA_EXPLOSAO - vai buscar os dados á tabela e desenha a EXPLOSÃO
; **
desenha_explosao:
    PUSH R11
    PUSH R10
    PUSH R6
    PUSH R5
    PUSH R4
    PUSH R3
    PUSH R2
    PUSH R1
    PUSH R0

    MOV R10, Explosao            ;Endereço do primeiro elemento da tabela que descreve o objeto FANTASMA
    MOV R11, Posicao_Pacman   ;Endereço do primeiro elemento da tabela que descreve a posição do objeto FANTASMA
    MOV  R1, [R11 + 2]            ;guardar posição y da tabela num registo
    MOV  R2, [R11]                ;guardar posição x da tabela num registo
    MOV  R3, [R10 + 4]            ;guardar cor do pixel num registo
    MOV  R4, [R10]                ;guardar comprimento x do objeto num registo
    MOV  R5, [R10 + 2]            ;guardar altura y do objeto num registo

    CALL desenha_objeto            ;Rotina que desenha todo o objeto descrito acima.

    POP R0
    POP R1
    POP R2
    POP R3
    POP R4
    POP R5
    POP R6
    POP R10
    POP R11

    RET