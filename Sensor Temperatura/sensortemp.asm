;************************************
;;************************************      Programa Multiplexor del PIC 16f877a
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
CNT3 ;Contador para delay (repite el multiplexado)
DIVISOR_A ;Variable para operaciones numéricas
DIVIDENDO_B ;Variable para operaciones numéricas
CONTAD ;Variable para operaciones numéricas
ACCUM ;Variable para operaciones numéricas
MULT_A ;Variable para operaciones numéricas

	ENDC

GODONE EQU 2

	ORG 0x00
    GOTO INIT
    ORG 0x04

;************************************
;
;   Tabla Lookup para 7 segmentos
;
;   Esta tabla convierte los números de formato binario decimal
;   a formato 7 segmentos
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

;********************************************************
;   Configuración de los registros de conversión ADC
;
;   ADCON1 tiene seteado el bit 7 para que el resultado
;   esté justificado a la derecha (pg 128 de datasheet)
;
;   ADCON0 tiene los bits ADCS en 001 (BITS 7 Y 6), la configuración
;   recomendada para relpojes externos menores a 5Hz
;
;   El bit 0 de ADCON0 se setea para activar el convertidor análogo digital
;
;********************************************************

    MOVLW b'10000000'
    MOVWF ADCON1
	BCF STATUS, RP0 ;Seleccionar banco 0
	CLRF PORTB      ;inicializar salidas de PuertoB en ceros
    MOVLW b'01000001'
    MOVWF ADCON0

;************************************
;
;   Programa principal
;
;
;************************************

MAIN:

    BSF ADCON0,GODONE ;se setea el bit de GO/DONE para inicar la converión ADC


; se checa continuamente hasta que el bit GODONE valaga 0 (se cpompletó la converisón)
CONVERSION:
    BTFSC ADCON0,GODONE
    GOTO CONVERSION

; se pasa el dato del registro de salida ADRESL (el d ebits bajos) a la variable para operaciones matemáticas
    MOVF ADRESL,0
    MOVWF MULT_A

;Se multiplica el valor por un factor (multiplicación por sumas)
    MOVLW d'2'
    MOVWF CONTAD
MULTIPLICAR:
    ADDWF MULT_A, 0
    DECFSZ CONTAD, 1
    GOTO MULTIPLICAR
    MOVWF DIVISOR_A

;Se divide el valor por un factor, Divisor A entre Dividendo B
    MOVLW d'1'
    MOVWF DIVIDENDO_B
    CLRF ACCUM
    MOVF DIVISOR_A ,0
    MOVWF CONTAD
    MOVF DIVIDENDO_B,0
DIVIDIR:
;Se checa si CONTAD A es menor a B
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 0
    BSF STATUS, C
;Si A es mayor que B, se resta sucesivamente hasta que llega a ser menor
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 1
    BTFSS STATUS, C
    GOTO SALIR_DIVISION
    INCF ACCUM,1
    GOTO DIVIDIR

SALIR_DIVISION:

;Se suma un factor de conversión a la variable
    MOVLW d'1'
    ADDWF ACCUM, 1

;Se pasa el resultado a DIVISOR_A
;y se desarrolla otra division, entre diez para sacar el digito más significativo
    MOVF ACCUM, 0
    MOVWF DIVISOR_A
    MOVLW d'10'
    MOVWF DIVIDENDO_B
    CLRF ACCUM
    MOVF DIVISOR_A ,0
    MOVWF CONTAD
    MOVF DIVIDENDO_B,0
DIVIDIR_10:
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 0
    BSF STATUS, C
    MOVF DIVIDENDO_B,0
    SUBWF CONTAD, 1
    BTFSS STATUS, C
    GOTO SALIR_DIVISION_10
    INCF ACCUM,1
    GOTO DIVIDIR_10

SALIR_DIVISION_10:

MOVF DIVISOR_A ,0
MOVWF CONTAD

;Se hace una operación de módulo para sacar el dígito menos significativo
;A % B a es contad y B es dividendo_B
MODULAR:
    MOVF CONTAD,0
    SUBWF DIVIDENDO_B, 0 ;Se checa si A=B
    BTFSC STATUS, Z
    GOTO IGUAL
    BSF STATUS, C
    MOVF DIVIDENDO_B, 0
    SUBWF CONTAD,0 ;se checa si A < B
    BTFSS STATUS, C
    GOTO SALIDA_MODULAR ; si son iguales, A es el modulo
    MOVF DIVIDENDO_B, 0
    SUBWF CONTAD,1 ; si A > B se le resta B a A y se guarda en A
    GOTO MODULAR

IGUAL: ; si son iguales, el modulo es 0
    CLRF CONTAD
    GOTO SALIDA_MODULAR

SALIDA_MODULAR:

;Se utiliza el contador CNT3 para ejecutar el multiplexeo 50 veces

    MOVLW d'50'
    MOVWF CNT3

MOSTRAR_DATOS:
    MOVLW b'10000000' ; Activar la primera salida para multiplexeo de display
    MOVWF PORTD
    MOVF CONTAD,0        ; Convertir el número cuatro a código 7 segmentos
    CALL TABLA
    MOVWF PORTB       ; Mostrar el númeor en display y esperar
	CALL RETARDO_1
    MOVLW b'01000000' ; Activar la segunda salida para multiplexeo de display
    MOVWF PORTD
    MOVF ACCUM,0        ; Convertir el número dos a código 7 segmentos
    CALL TABLA
    MOVWF PORTB       ; Mostrar el númeor en display y esperar
    CALL RETARDO_1
    CLRW
    DECFSZ CNT3,1
    GOTO MOSTRAR_DATOS

	GOTO MAIN

;************************************
;   RETARDO_1
;
;   Rutina de Delay para Multiplexado
;   1000 conteos de 1 ciclo
;   CNT2 ---> 10
;   CNT1 ---> 10
;   CNT0 ---> 10
;
;************************************


RETARDO_1:
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




