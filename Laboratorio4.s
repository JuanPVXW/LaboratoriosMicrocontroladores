; Documento:	Laboratorio4
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Interrupciones Tmr0 y IOCB, pull up interno
; Creado: 15 febrereo, 2021
;-----------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 
  
 UP	EQU 0		//Valor asignado a UP
 DOWN	EQU 7		//Valor aignado a UP
	
reiniciar_Tmr0 macro	//macro 
    banksel TMR0	//Banco de TMR0
    movlw   178		//Mover el valor literal al registro w
    movwf   TMR0	//Mover el valor literal a TMR0
    bcf	    T0IF	//Limpiar la bandera de TMR0 para reinicio 
    endm		//Final de macro 
    
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;2 byte apartado
    Display2:	DS  1 ;1 Byte apartado 
    
  PSECT udata_shr ;common memory
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  ;----------------------interripción reset------------------------
  ORG 04h	;posición 0004h para interr
  push:
    movf    w_temp	//mover f(w_temp) a w
    swapf   STATUS, W	//Intercambiar los nibles del status y guardar en w
    movwf   STATUS_TEMP	//Mover el STATUS intercambiado a Status temporal 
  isr:
    btfsc   T0IF	//Revisamos la bandera de carry de TMR0
    call    Interr_Tmr0	//Si la bandera es 1, llamamos a la subrutina de interr
    btfsc   RBIF	//Revisamos la bandera de cambio de estado de bits RBIF	
    call    int_ioCB	//si la bandera es 1, llamamos a la subrutina de IOCB
  pop:
    swapf   STATUS_TEMP, W  //Intercambiar nibbles de status temporal, guardar en w
    movwf   STATUS	    //Mover w a STATUS
    swapf   w_temp, F	    //intercambiar nibles de w_temp y guardar en F (Mismo registro)
    swapf   w_temp, W	    //Intercambiar nibles de w_temp y guardar en w
    retfie
;---------SubrutinasInterrupción-----------
  Interr_Tmr0:
    reiniciar_Tmr0	;20 ms     macro
    incf    cont	//incrementar cont
    movf    cont, W	//mover cont a w
    sublw   50		//Resta entre literal y w(cont)
    btfss   STATUS, 2	;Bit zero status, revisar si esta levantada la bandera
    goto    return_T0	;$+2  
    clrf    cont	;Limpiar varible cont
    incf    Display2	;incrementar variable Display2
 
 return_T0:
    return		//ejercutar return
 int_ioCB:
    banksel PORTB	//Banco donde se encuentra PORTB
    btfss   PORTB, UP	//Revisar si esta encendido el bit UP=0 del PORTB
    incf    PORTA	//Incrementar valor de PORTA, si el bit UP esta apagado
    btfss   PORTB, DOWN	//Revisar si esta encendido el bit DOWN=UP del PORTB
    decf    PORTA	//Decrementar PORTA si el bit Down este en 0
    bcf	    RBIF	//Limpiar la bandera de cambio de estado de bits de RB
    return
    
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
;-----------------Tabla-----------------------------
Tabla:
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
  ;---------------configuración------------------------------
  main: 

    call    config_io
    call    config_reloj
    call    config_tmr0
    call    config_IOChange
    call    config_InterrupEnable  
    banksel PORTA 
;----------loop principal---------------------
 loop: 
    movf    Display2,w	    //Mover valor de variable Display2 a w
    call    Tabla	    //Llamamos a la etiqueta Tabla 
    movwf   PORTD	    //Mover el valor de w proveniente de las tablas a PORTD
    
    movf    PORTA,w	    //Mover valor de PORTA a w
    call    Tabla	    //Llamamos a la etiqueta tabla
    movwf   PORTC	    //Mover valor de w al PORTC
    
    goto    loop    ;loop forever 
;------------sub rutinas---------------------
config_IOChange:
    banksel TRISA	
    bsf	    IOCB, UP	;Habilitar bit control UP=0 de Interrupt_On_Change del PORTB
    bsf	    IOCB, DOWN	;Habiliat bit DOWN de IOCB
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    bcf	    RBIF	;Limpiar bandera de bit de interrupción de cambio de PORTB
    return
config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    movlw   0xF0
    movwf   TRISA	;PORTA A salida
    clrf    TRISD
    clrf    TRISC
    bsf	    TRISB, UP	;
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, UP	    ;Habilitar Pull up interno de pin UP=0 de PORTB
    bsf	    WPUB, DOWN	    ;Habilitar Pull up interno de pin DOWN=7 de PORTB
    

    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTD
    clrf    PORTC
    return
     
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
    reiniciar_Tmr0  ;Macro reiniciar tmr0
    return  
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 4Mhz
    return

config_InterrupEnable:
    bsf	    GIE		;Habilitar en general las interrupciones
    bsf	    T0IE	;Se encuentran en INTCON, bit de interrupción Overflow tmr0
    bcf	    T0IF	;Limpiamos bandera de overflow
    return
 
end
