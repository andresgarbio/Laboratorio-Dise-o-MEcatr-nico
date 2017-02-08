;************************************
;      Programa Multiplexor del PIC 16f877a
;
;************************************
    list p=16F877a
    #include <p16F877A.inc>

;*******************************
;Bits de configuración del PIC
;
;FOSC HS "High Speed Crystal/Resonator oscillator" ( 4MHz a 20MHz )
;WDTE Watchdog Timer
;PWRTE Power up timer
;BOREN Brown out Reset
;LVP Low voltage in circuit serial programming
;CPD Code Protection Bit Off
;WRT Flash program Memory Write
;CP Flash Program Memory Code Protection
;********************************

 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;************************************
;
;   Declaración de registros a usarse
;
;************************************

	CBLOCK 0x20
CNT0 ;Contador para delay
CNT1 ;Contador para delay
CNT2 ;Contador para delay
DIVISOR_A
DIVIDENDO_B
CONTAD
ACCUM

	ENDC

	ORG 0x00
    GOTO INIT
    ORG 0x04

;************************************
;
;   Tabla Lookup para 7 segmentos
;
;
;************************************

TABLA:
    addwf PCL, 1
    retlw b'00000010' ;0
    retlw b'10011110' ;1
    retlw b'00100100' ;2
    retlw b'00001100' ;3
    retlw b'10011000' ;4
    retlw b'01001000' ;5
    retlw b'01000000' ;6
    retlw b'00011110' ;7
    retlw b'00000000' ;8
    retlw b'00001000' ;9


INIT:
	BSF STATUS, RP0 ;Seleccionar banco 1
	CLRF TRISB      ;Se deja Puerto B como salidas
    CLRF TRISD      ;Se deja puerto D como salidas
    BCF STATUS, RP0

;************************************
;
;   Programa principal
;
;
;************************************

MAIN:

    MOVLW d'2'
    MOVWF DIVISOR_A
    MOVLW d'10'
    MOVWF DIVIDENDO_B
    CLRF ACCUM
    MOVF DIVISOR_A ,0
    MOVWF CONTAD
    MOVF DIVIDENDO_B,0


DIVIDIR:
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 0
    BSF STATUS, C
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 1
    BTFSS STATUS, C
    GOTO SALIR_DIVISION
    INCF ACCUM,1
    GOTO DIVIDIR

SALIR_DIVISION:
    MOVLW b'10000000' ; Activar la primera salida para multiplexeo de display
    MOVWF PORTD
    MOVF ACCUM,0        ; Convertir el número cuatro a código 7 segmentos
    CALL TABLA
    MOVWF PORTB       ; Mostrar el númeor en display y esperar
	CALL DELAY1
    MOVLW b'01000000' ; Activar la segunda salida para multiplexeo de display
    MOVWF PORTD
    MOVLW d'2'        ; Convertir el número dos a código 7 segmentos
    CALL TABLA
    MOVWF PORTB       ; Mostrar el númeor en display y esperar
    CALL DELAY1
	GOTO MAIN

;************************************
;   Delay1
;
;   Rutina de Delay para Multiplexado
;   1000 conteos de 1 ciclo
;   CNT2 ---> 10
;   CNT1 ---> 10
;   CNT0 ---> 10
;
;************************************


DELAY1:
	MOVLW 0xA  ;se inicializa el contador CNT2
	MOVWF CNT2
D2:
	MOVLW 0xA
	MOVWF CNT1 ;se inicializa el contador CNT1
D1:
	MOVLW 0xA
	MOVWF CNT0 ;se inicializa el contador CNT1
D0:
	DECFSZ CNT0 ;se decrementa CNT0 en ciclo hasta 0
	GOTO D0
	DECFSZ CNT1 ;se decrementa CNT1 (reiniciando CNT0) en ciclo hasta 0
	GOTO D1
	DECFSZ CNT2 ;se decrementa CNT2 (reiniciando CNT0, CNT1) en ciclo hasta 0
	GOTO D2

	RETURN





end


