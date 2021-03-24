; Documento: Laboratorio6
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Tmr0, Tmr1 y Tmr2
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

 UP	EQU 0	//Valor asignado a UP
 DOWN	EQU 1	//Valor aignado a DOWN

reiniciar_Tmr1 macro	//macro reiniciar Tmr1
    movlw   0x0B	//1 segundo
    movwf   TMR1H	//Asignar valor a TMR1H
    movlw   0xDC
    movwf   TMR1L	//Asignar valor a TMR1L
    bcf	    TMR1IF	//Limpiar bandera de carry/interrupción de Tmr1
    endm
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   132	//2 ms 
    movwf   TMR0	//Mover w al registro f(TMR0(
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
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
    cont:	DS  1
    var:	DS  1 ;1 byte apartado
    displayvar2:    DS	2;
    banderas:	DS  1
    nibble:	DS  2
    display_var:    DS	2
    centena:	DS  1
    centena1:	DS  1
    decena:	DS  1
    decena1:	DS  1
    unidad1:	DS  1
    unidad:	DS  1
    V1:		DS  1	    //Variables 
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
    btfsc   T0IF	    ;Si el timer0  levanta ninguna bandera de interrupcion
    call    Interr_Tmr0	    ;Rutina de interrupcion del timer0
    
    btfsc   TMR1IF	    ;Si el timer1  levanta ninguna bandera de interrupcion
    call    Interr_Tmr1	    ;Rutina de interrupcion del timer0
    
    btfsc   TMR2IF	    ;Si el timer1  levanta ninguna bandera de interrupcion
    call    Interr_Tmr2	    ;Rutina de interrupcion del timer0
  pop:
    swapf   STATUS_TEMP, W   //Intercambiar nibbles de status temporal, guardar en w
    movwf   STATUS	//Mover w a STATUS
    swapf   w_temp, F	//intercambiar nibles de w_temp y guardar en F (Mismo registro)
    swapf   w_temp, W	//Intercambiar nibles de w_temp y guardar en w
    retfie
;---------SubrutinasInterrupción-----------
Interr_Tmr0:
    reiniciar_Tmr0	;2 ms
    bcf	    STATUS, 0	    ;Dejo el STATUS 0 en un valor de 0
    clrf    PORTD	    ;Limpio el puerto D
    btfsc   PORTB, 0	    ;Revisar si el pin de LED esta apagado
    goto    offdisplay	    ;Llamar subrutina offdisplay
    btfsc   banderas, 1	    ;Revisar bit 1 de banderas
    goto    displayunidad   ;Llamar a subrutina de displayunidad	    ;
    btfsc   banderas, 2	    ;Revisar bit 2 de banderas
    goto    displaydecena   ;Llamar a subrutina de displaydecena
    movlw   00000001B
    movwf   banderas	    ;Mover literal a banderas
siguientedisplay:
    RLF	    banderas, 1	    ;Rota a la izquierda los bits de variable banderas
    return

offdisplay:
    bcf	    PORTD, 0	    ;Apagar transistor de display
    bcf	    PORTD, 1	    ;Apagar transistor de display
    return
displaycentena: 
    movf    centena1, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTD
    bsf	    PORTD, 2	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay	//Siguiente display
displaydecena:
    movf    decena1, w	    //Mover el valor de decena1(Tabla) a w
    movwf   PORTC	    //Mover el valor de w a PORTD
    bsf	    PORTD, 1	    //Encender bit 5 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
displayunidad:
    movf    unidad1, w	    //Mover el valor de Unidad1(Tabla) a w
    movwf   PORTC	    //mover el valor de w a PORTD
    bsf	    PORTD,0	    //Encender bit 5 de PORTB para transistor
    goto    siguientedisplay	//Siguiente display
    
Interr_Tmr1:
    reiniciar_Tmr1
    incf    cont
    return

Interr_Tmr2:
    reiniciar_tmr2
    incf    PORTB
    return
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
    call    config_tmr0
    call    config_tmr1
    call    config_tmr2
    call    config_InterrupEnable  
    banksel PORTA 
;----------loop principal---------------------
 loop:
    movf    cont, w
    movwf   V1
    call    divcentenas	//Subrutina de división para contador DECIMAL 
    call    displaydecimal
    goto    loop    ;loop forever 
;------------sub rutinas--------------------
;separar_nibbles:
    ;movf    cont+1, w	    ;Var tiene el valor del contador
    ;andlw   0x0f	    ;Obtenemos los 4 bits menos significativos
    ;movwf   nibble	    ;los pasamos a nibble
    ;swapf   cont+1, w	    ;volteamos la variable var
    ;andlw   0x0f	    ;obtenemos los 4 bits mas significativos
    ;movwf   nibble+1	   ; Los pasamos a nibble+1
    ;return

;config_displays:
    ;movf    nibble, w	    ;Movemos el valor de nibble a w
    ;call    Tabla	    ;Movemos w a la tabla
    ;movwf   display_var	    ;el valor de w preparado para el display lo madamos a la variable display_var
    ;movf    nibble+1, w	    ;
    ;call    Tabla
    ;movwf   display_var+1
    ;return
displaydecimal:
    movf    centena, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena1	//Lo guardamos en variable centena1
    movf    decena, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena1	//Lo guardamos en variable decena1
    movf    unidad, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad1	//Lo guardamos en variable unidad1
    return
divcentenas:
    clrf    centena	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V1, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS	 //llama a subrutina para resta en decena
    incf    centena, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS:
    clrf    decena	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V1		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V1,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES:
    clrf    unidad	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V1		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V1,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
    
config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    bcf     TRISB, 0
    clrf    TRISC
    bcf	    TRISD, 0
    bcf	    TRISD, 1

    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTB	;Valor incial 0 en puerto A, C y D
    clrf    PORTC
    clrf    PORTD
    return
     
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0	    ;PS = 001 Tiempo en ejecutar , 1:4
    
    reiniciar_Tmr0  ;Macro reiniciar tmr0
    return  
 config_tmr1:
    banksel T1CON
    bcf	    TMR1GE	;tmr1 como contador
    bcf	    TMR1CS	;Seleccionar reloj interno (FOSC/4)
    bsf	    TMR1ON	;Encender Tmr0
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
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return

config_InterrupEnable:
    banksel T1CON
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    PEIE
    bcf	    TMR1IF	;Limpiamos bandera de overflow de tmr1
    bcf	    TMR2IF	;Limpiamos bandera de overflow de tmr2
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    banksel PIE1
    bsf	    T0IE	;Habilitar bit de interrupción tmr0
    bsf	    TMR1IE	;Habilitar bit de interrupción Tmr1
    bsf	    TMR2IE	;Habilitar bit de interrupción Tmr2
    return
 
end
