; Documento: 
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Proyecto1Semaforo_3vías
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

 MODO	EQU 0
 INC	EQU 1
 DECRE	EQU 2
	
reiniciar_Tmr0 macro	//macro
    ;banksel TMR0	//Banco de TMR0
    movf    T0_Actual, W
    movwf   TMR0        ;T0_Actual a TMR0
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
    endm
reiniciar_Tmr1 macro	//macro reiniciar Tmr1
    movlw   0x0B	//1 segundo
    movwf   TMR1H	//Asignar valor a TMR1H
    movlw   0xDC
    movwf   TMR1L	//Asignar valor a TMR1L
    bcf	    TMR1IF	//Limpiar bandera de carry/interrupción de Tmr1
    endm
reiniciar_tmr2 macro	//Macro reinicio Tmr2
    banksel PR2
    movlw   244		//Mover valor a PR2
    movwf   PR2		
    
    banksel T2CON
    clrf    TMR2	//Limpiar registro TMR2
    bcf	    TMR2IF	//Limpiar bandera para reinicio 
    endm
    
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;2 byte apartado
    Tmr0_temporal:   DS	1
    T0_Actual:	    DS	1
    estado:	DS  1
  PSECT udata_shr ;common memory
    w_temp:	DS  1;1 byte apartado
    STATUS_TEMP:DS  1;1 byte
    PCLATH_TEMP:    DS	1
  
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
    movf    w_temp
    swapf   STATUS, W
    movwf   STATUS_TEMP
    movf    PCLATH, W
    movwf   PCLATH_TEMP
  isr:
    btfsc   RBIF
    call    int_ioCB
    
    ;btfsc   T0IF
    ;call    Interr_Tmr0
  pop:
    movf    PCLATH_TEMP, W
    movwf   PCLATH
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   w_temp, F
    swapf   w_temp, W
    retfie
;---------SubrutinasInterrupción-----------
int_ioCB:
    movf    estado, W
    clrf    PCLATH		
    andlw   0x03
    addwf   PCL
    goto    interrup_estado_0
    goto    interrup_estado_1
    goto    interrup_estado_2; 0
 interrup_estado_0:
    banksel PORTB
    btfsc   PORTB, MODO
    goto    finalIOC
    incf    estado
    movf    T0_Actual, W
    movwf   Tmr0_temporal
    goto    finalIOC
 
 interrup_estado_1:
    btfss   PORTB, INC
    incf    Tmr0_temporal
    btfss   PORTB, DECRE
    decf    Tmr0_temporal
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC    
 interrup_estado_2:
    btfss   PORTB, DECRE
    clrf    estado
    btfsc   PORTB, INC
    goto    finalIOC
    movf    Tmr0_temporal, W
    movwf   T0_Actual
    clrf    estado
 finalIOC:
    bcf	    RBIF
    return
    
  ;Interr_Tmr0:
    ;reiniciar_Tmr0	;50 ms
    ;incf    cont
    ;movf    cont, W
    ;sublw   10
    ;btfss   STATUS, 2	;Bit zero status
    ;goto    return_T0	;$+2
    ;clrf    cont	;500ms
    ;incf    PORTA
 ;return_T0:
    ;return
    
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
 ;------------------ TABLA -----------------------
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
    call    config_IOChange
    call    config_tmr0
    call    config_InterrupEnable  
    banksel PORTA 
    movlw   0xFF
    movwf   PORTA
    clrf    estado
;----------loop principal---------------------
 loop:
    btfss   T0IF
    goto    $-1
    reiniciar_Tmr0	;call    TiempoDelay_Tmr0 ;reiniciar_Tmr0
    decf    PORTA
    
    bcf	    GIE
    movf    estado, W
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0x03
    addwf   PCL
    goto    estado_0
    goto    estado_1
    goto    estado_2
 estado_0:
    bsf	    GIE
    clrf    PORTD
    movlw   00000001B
    movwf   PORTC
    
    goto    loop    ;loop forever
 estado_1:
    bsf	    GIE
    movf    Tmr0_temporal, W
    movwf   PORTD
    movlw   00000010B
    movwf   PORTC
    goto    loop
 estado_2:
    bsf	    GIE
    movf    Tmr0_temporal, W
    movwf   PORTD
    movlw   00000100B
    movwf   PORTC
    goto    loop
;------------sub rutinas---------------------
config_IOChange:
    banksel TRISA
    bsf	    IOCB, MODO
    bsf	    IOCB, INC
    bsf	    IOCB, DECRE
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    ;bcf	    RBIF
    ;bsf	    GIE
    ;bsf	    RBIE
    return
config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    clrf    TRISA	;PORTA A salida
    clrf    TRISC
    clrf    TRISD
    bsf	    TRISB, MODO
    bsf	    TRISB, INC
    bsf	    TRISB, DECRE
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, MODO
    bsf	    WPUB, INC
    bsf	    WPUB, DECRE
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    ;clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTC
    clrf    PORTB
    clrf    PORTD
    return
    
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
    banksel PORTA
    movlw   61
    movwf   T0_Actual
    reiniciar_Tmr0  ;Macro reiniciar tmr0
    return
    
 config_tmr1:
    banksel T1CON
    bcf	    TMR1GE	;tmr1 como contador
    bcf	    TMR1CS	;Seleccionar reloj interno (FOSC/4)
    bsf	    TMR1ON	;Encender Tmr1
    bcf	    T1OSCEN	;Oscilador LP apagado
    bsf	    T1CKPS1	;Preescaler 10 = 1:4
    bcf	    T1CKPS0 
    
    reiniciar_Tmr1
    return
    
 config_tmr2:
    banksel T2CON
    bsf	    T2CON, 7 
    bsf	    TMR2ON
    bsf	    TOUTPS3	;Postscaler 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    bsf	    T2CKPS1	;Preescaler 1:16
    bsf	    T2CKPS0
    
    reiniciar_tmr2
    return
    
 TiempoDelay_Tmr0:
    reiniciar_Tmr0	
    incf    cont	//incrementar cont
    movf    cont, W	//mover cont a w
    sublw   5		//Resta entre literal y w(cont)
    btfss   STATUS, 2	;Bit zero status, revisar si esta levantada la bandera
    goto    return_T0	;$+2  
    clrf    cont	;Limpiar varible cont
    incf    PORTA;incf    Display2	;incrementar variable Display2
 return_T0:
    return		//ejecutar return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return

config_InterrupEnable:
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    ;bsf	    T0IE	;Habilitar bit de interrupción tmr0
    ;bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    return
 
end
