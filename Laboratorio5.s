; Documento: Laboratorio5 
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Contadores y múltiples displays
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
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   221		//9 ms 
    movwf   TMR0	//Mover w al registro f(TMR0(
    bcf	    T0IF	//Limpiar bandera de overflow para reinicio 
    endm
    
  PSECT udata_bank0 ;common memory
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
    btfsc   RBIF	//Revisamos la bandera de cambio de estado de bits RBIF	
    call    int_ioCB	//si la bandera es 1, llamamos a la subrutina de IOCB
    
    btfsc   T0IF	//Revisamos la bandera de carry de TMR0
    call    Interr_Tmr0	//Si la bandera es 1, llamamos a la subrutina de interr
  pop:
    swapf   STATUS_TEMP, W   //Intercambiar nibbles de status temporal, guardar en w
    movwf   STATUS	//Mover w a STATUS
    swapf   w_temp, F	//intercambiar nibles de w_temp y guardar en F (Mismo registro)
    swapf   w_temp, W	//Intercambiar nibles de w_temp y guardar en w
    retfie
;---------SubrutinasInterrupción-----------
int_ioCB:
    banksel PORTB	//Banco de PORTB
    btfss   PORTB, UP	//Revisamos el bit 0 de PORTB
    incf    PORTA	//Si el bit 0 es 0, incrementa PORTA
    btfss   PORTB, DOWN	//Revisamos el bit1 de PORTB
    decf    PORTA	//Si bit 1 es 0, Decrementa PORTA
    bcf	    RBIF	//Limpiamos bandera de cambio de IOCB, para resetear pines
    return
Interr_Tmr0:
    reiniciar_Tmr0	;9 ms
    bcf     STATUS, 0	//Limpiar bit de Carry de STATUS
    clrf    PORTB	//Limpiar PORTB para la configuración IOCB y bit de encendido de displays
    btfsc   banderas, 1	//Revisar bit 1 de banderas
    goto    display0	//Subrutina para encender display0(Hexadecimal)
    btfsc   banderas, 2	//Revisar bit 2 de banderas
    goto    display1	//Subrutina de display 1 para contador hexadecimal
    btfsc   banderas, 3	//Revisar bit 3 de banderas 
    goto    displaycentena  //Subrutina para encender display de centena
    btfsc   banderas, 4	//Revisar bit 4 de banderas
    goto    displaydecena   //Subrutina para encender display de decena
    btfsc   banderas, 5	//Revisar bit 5 de banderas
    goto    displayunidad   //Subrutina para encender display de unidad
    movlw   00000001B	//Mover valor literal a W
    movwf   banderas	//Mover valor literal a variable banderas
siguientedisplay:	//Subrutina para cambiar de display
    RLF	    banderas, 1	//Rota a la izquierda los bits de variable banderas
    return
display0:		
    movf    display_var, w  //Mover variable a w (Valor hexadecimal de tabla)
    movwf   PORTC	    //Valor de variable al PORTC
    bsf	    PORTB, 2	    //Encender bit 2 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
display1:
    movf    displayvar2, w  //Mover variable a w(Valor hexadecimal) otrp nibble
    movwf   PORTC	    //Mover valor de variable a PORTC
    bsf	    PORTB, 3	    //Encender bit 3 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
displaycentena: 
    movf    centena1, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTD	    //Mover w a PORTD
    bsf	    PORTB, 4	    //Encender bit4 de PORTB para transistor 
    goto    siguientedisplay	//Siguiente display
displaydecena:
    movf    decena1, w	    //Mover el valor de decena1(Tabla) a w
    movwf   PORTD	    //Mover el valor de w a PORTD
    bsf	    PORTB, 5	    //Encender bit 5 PORTB para transistor
    goto    siguientedisplay	//Siguiente display
displayunidad:
    movf    unidad1, w	    //Mover el valor de Unidad1(Tabla) a w
    movwf   PORTD	    //mover el valor de w a PORTD
    bsf	    PORTB,6	    //Encender bit 5 de PORTB para transistor
    goto    siguientedisplay	//Siguiente display
    
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
    ;movlw   01011011B
    ;movwf   unidad1
    ;movlw   00000110B
    ;movwf   decena1
    ;movlw   00111111B
    ;movwf   centena1
;----------loop principal---------------------
 loop:
    movf    PORTA, w	//Valor de PORTA mover a w
    movwf   var		//Valor de PORTA a variable var
    movwf   V1		//Valor de PORTA a variable V1
    //Llamar a subrutinas 
    call    separar_nibbles	
    call    displays_hexadecimal 	
    call    divcentenas	//Subrutina de división para contador DECIMAL 
    call    displaydecimal

    goto    loop    ;loop forever 
;------------sub rutinas--------------------
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
separar_nibbles:
    movf    var, w	//Mover el valor de var(PORTA) a w
    andlw   0x0f	//Los 4 bits menos significativos los guardamos en nibble
    movwf   nibble
    swapf   var, w	//Intercambiamos nibbles de var(PORTA) y movemos a w
    andlw   0x0f	//Los 4 bits menos significativos lo guardamos en siguiente nibble 
    movwf   nibble+1
    return
displays_hexadecimal:
    movf    nibble, w	//Asignar el valor de nibble un valor de la Tabla 
    call    Tabla
    movwf   display_var	//Guardar ese valor de la tabla en display_var
    movf    nibble+1, w	//Asignar el valor de otro nibble un valor de la tabla
    call    Tabla	
    movwf   displayvar2	//Guardar en display var2
    return
config_IOChange:
    banksel TRISA
    bsf	    IOCB, UP	//Habilitar los bits UP Y DOWN como IOCB
    bsf	    IOCB, DOWN 
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
    bcf	    RBIF
    return
config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6	;Banksel ANSEL
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    clrf    TRISA	;PORTA A salida
    clrf    TRISC	;PORTA C salida
    clrf    TRISD	;PORTA D salida
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN
    bcf	    TRISB, 2	//Bits de salida de PORTB
    bcf	    TRISB, 3
    bcf	    TRISB, 4
    bcf	    TRISB, 5
    bcf	    TRISB, 6
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, UP	    ;Habilitar Pull up interno de pin UP=0 de PORTB
    bsf	    WPUB, DOWN	    ;;Habilitar Pull up interno de pin DOWN=0 de PORTB
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A, C y D
    clrf    PORTC
    clrf    PORTD
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
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera
    bsf	    T0IE	;Habilitar bit de interrupción tmr0
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    return
 
end
