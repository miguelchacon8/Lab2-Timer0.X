;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Miguel Chacón   
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: lab 2 - TMR0 y Botones
; Hardware: PIC16F887
; Creado: 31/07/22
; Última Modificación: 2/08/22 
;******************************************************************************* 
PROCESSOR 16F887
#include <xc.inc>
;******************************************************************************* 
; Palabra de configuración    
;******************************************************************************* 
 ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits 
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit 
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit 
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit 
  CONFIG  CP = OFF              ; Code Protection bit 
  CONFIG  CPD = OFF             ; Data Code Protection bit 
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits 
  CONFIG  IESO = OFF            ; Internal External Switchover bit 
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit 

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit 
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
;******************************************************************************* 
; Variables    
;******************************************************************************* 
PSECT udata_shr
flag:
    DS 1
PSECT udata_bank0
COMP:
    DS 1
contdisplay:
    DS 1   
cont1s:
    DS 1
;******************************************************************************* 
; Vector Reset    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0000
    goto MAIN
;******************************************************************************* 
; Código Principal    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0100
 
valores: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F
    ADDWF PCL
    ; cátodo
    RETLW 00111111B  ;0
    RETLW 00000110B  ;1
    RETLW 01011011B  ;2
    RETLW 01001111B  ;3
    RETLW 01100110B  ;4
    RETLW 01101101B  ;5
    RETLW 01111101B  ;6
    RETLW 00000111B  ;7
    RETLW 01111111B  ;8
    RETLW 01100111B  ;9
    RETLW 01110111B  ;A
    RETLW 01111100B  ;B
    RETLW 00111001B  ;C
    RETLW 01011110B  ;D
    RETLW 01111001B  ;E
    RETLW 01110001B  ;F
   
MAIN:
    
BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; analógicos desactivados
    
BANKSEL OSCCON
    ; Frecuencia del oscilador
    BSF OSCCON, 6	; IRCF2 Selección de 2 MHz
    BCF OSCCON, 5	; IRCF1
    BSF OSCCON, 4	; IRCF0
    
    BSF OSCCON, 0	; SCS Reloj Interno
    

; Configuración TMR0 **********************************************************
BANKSEL OPTION_REG ;TEMPORIZADOR DEL TMR0
    BCF OPTION_REG, 5	; T0CS: FOSC/4 COMO RELOJ (MODO TEMPORIZADOR)
    BCF OPTION_REG, 3	; PSA: ASIGNAMOS EL PRESCALER AL TMR0
    
    BSF OPTION_REG, 2
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; PS2-0: PRESCALER 1:256 SELECIONADO 
  
;****************************************************************************
; OUTPUTS E INPUTS*
;****************************************************************************
BANKSEL TRISB
    CLRF TRISB
    CLRF TRISC
    CLRF TRISD ; puertos b, c y d como out
    
    BSF TRISA, 0 
    BSF TRISA, 1 ;push bottons como inputs
    ; bcf TRISA, 3 ; led de alarma
BANKSEL PORTA
    CLRF PORTA ;push buttons y alarma 
    CLRF PORTB ;display
    CLRF PORTD ; contador segundos
    CLRF PORTC ; contador timer0
    CLRF cont1s	; Se limpia la variable cont100ms
    MOVLW 61
    MOVWF TMR0		; CARGAMOS EL VALOR DE N = DESBORDE 100mS
    CLRF contdisplay

    
;***************************************************************************
    ;LOOP
;***************************************************************************
LOOP:
    ;tmr0 ****************************************************
    INCF PORTC	; Incrementamos el Puerto B
    ;contador de 4 bits en 7 segmentos
    BTFSC PORTA, 0	    ; revisa rb7
    CALL anti1	    ; si se presiona se ejecuta anti1
    BTFSS PORTA, 0
    CALL push1	    ; si se presiona se ejecuta push1
    BTFSC PORTA, 1	    ; Revisa RA1
    CALL anti2
    BTFSS PORTA, 1
    CALL push2
    CALL comparar
    
comparar:
    MOVWF TMR0
    BCF STATUS, 2
    MOVF COMP, W
    ANDLW 0X0F
    MOVWF COMP
    MOVD PORTD, W
    SUBWF COMP, W
    BTFSS STATUS, 2
    GOTO LOOP
    CLRF PORTD
    GOTO LOOP
    GOTO verificacion
    
        
verificaciontmr:    
    BTFSS INTCON, 2	; Verificamos si la bandera T0IF = 1?
    GOTO $-1
    BCF INTCON, 2	; Borramos la bandera T0IF
    MOVLW 61
    MOVWF TMR0
    INCF cont1s, F
    call verificacion
    GOTO LOOP		; Regresamos a la etiqueta LOOP

verificacion:  
    movf cont1s, w
    SUBLW 10
    BTFSS STATUS, 2	; verificamos bandera z
    RETURN
    CLRF cont1s
    INCF PORTD
    MOVLW 61
    MOVWF TMR0
    GOTO LOOP		; Regresamos a la etiqueta LOOP
 
anti1:
    BSF flag, 0    ; si se presiona se enciende bit 0
    RETURN
    
push1:
    BTFSS flag, 0	;skip si = 0
    RETURN
    INCF contdisplay, F
    MOVF contdisplay, W
    CALL valores
    MOVWF PORTB
    CLRF flag
    RETURN
    
anti2:
    BSF flag, 1	; si se presiona se enciende bit 1
    RETURN

push2:
    BTFSS flag, 1
    RETURN
    DECF contdisplay, F	; decrementa PORTC
    MOVF contdisplay, W	; valor a w cuando se decrementa de 0 a F
    CALL valores
    MOVWF PORTB; lo carga a PORTB
    CLRF flag		; Bits de la bandera en 0 
    RETURN


;******************************************************************************* 
; Fin de Código    
;******************************************************************************* 
END   






