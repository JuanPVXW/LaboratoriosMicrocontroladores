; Documento:	Laboratorio3 
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Contadodores 4 bits, Display 7 segmentos y Alarma 
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

;------------------------------
  ;PSECT udata_bank0 ;common memory
    ;cont:	DS  2 ;1 byte apartado
    ;cont_big:	DS  1;1 byte apartado
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
  
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
;---------------Tabla----------------------
    TablaDisplay:
    clrf  PCLATH	    ;Limpiar bits de PCLATH
    bsf   PCLATH,0	    ;Set bit0 de PCLATH
    andlw 0x0F		    ;4 bits menos significativos como entradas
    addwf PCL	;Habiltamos los 4 bits de memoeria del PCL para el registro PCLATH 
    retlw 00111111B          ; 0 - Guarda el valor de la literal en W
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
;---------------Configuración------------------------------
  main: 
    call    config_io
    call    config_reloj
    call    config_timr0
    banksel PORTA
;----------loop principal---------------------
loop: 
    
    btfss   T0IF	;Revisamos si la bandera IF esta activa (Carry Tmr0)
    goto    $-1		;Ejectuamos linea anterior
    goto    loop	    ;Ejecutamos de nuevo toda la etiqueta 
    call    reiniciar_timr0 ; Llamamos a la etiqueta del reincio del Tmr
    incf    PORTB	    ;Incrementamos PORTB
    
    btfsc   PORTA, 0	;Revisar que no este presionado 
    call    inc_portD	;LLamamos a la etiqueta de incremento del PortD
    btfsc   PORTA, 1	;Revisar que no esta presionado 
    call    dec_portD	;Llamamos a la etiqueta de incremento del PortD
    
    movf    PORTD, w	;Mover el valor de "f"(PORTD) a w 
    call    TablaDisplay    ;Llamamos la etiqueta de configuración de la Tabla
    movwf   PORTC	;Mover w al registro f(PORTC)
    
    incf    PORTD,w	;Incrementamos PORTD y guardamos a w
    subwf   PORTB,w	;Restamos w-f, PORTD - PORTB y guardamos en w
    
    btfsc   STATUS,2	;Revisamos si la bandera "Z" no esta activa del STATUS
    call    ResetTmr0	;Llamamos a la etiqueta ResteTmr0
    btfss   STATUS,2	;Revisamos si la bandera "Z" esta activa 
    bcf	    PORTA,2	;Apagamos Led de alarma
    
    goto    loop    ;loop forever    
;-------Configuración Entradas y Salidas--------------------------   
 config_io:
    bsf	    STATUS, 5   ;banco  11    - Banksel ANSEL 
    bsf	    STATUS, 6	
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6	;Banksel TRISA
    movlw   0xF0
    movwf   TRISB	;PORTA B salida
    movlw   11111011B	;Movemos lietal a W para definir I/O
    movwf   TRISA	;w a f, para deinir I/O para PORTA
    movlw   0xF0	
    movwf   TRISD	;4 bits menos significativos de PORTD como salidas
    clrf    TRISC	;Todo el PORTC como salida
    
    bcf	    STATUS, 5	;banco 00  - Banksel PORTA
    bcf	    STATUS, 6	
    clrf    PORTB	;Valor incial 0 en puerto A, B, C y D
    clrf    PORTA
    clrf    PORTD
    clrf    PORTC   
    return
;------------sub rutinas---------------------
ResetTmr0:
    bsf	    PORTA,2	;Encendemos el Led de alarma 
    clrf    PORTB	;Reseteamos todo el puerto B 
    return		
inc_portD:
    ;call    delay_small
    btfsc   PORTA, 0	;Revisa de nuevo si no esta presionado
    goto    $-1		;ejecuta una linea atrás	        
    incf    PORTD
    return
dec_portD:
    ;call    delay_small
    btfsc   PORTA, 1	;Revisa de nuevo si no esta presionado
    goto    $-1		;ejecuta una linea atrás	        
    decf    PORTD
    return
 config_timr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS	;reloj interno clock selection
    bcf	    PSA		;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0		;PS = 111 Tiempo en ejecutar , 256
    
    banksel TMR0
    call    reiniciar_timr0
    return
 reiniciar_timr0: 
    movlw   134
    movwf   TMR0
    bcf	    T0IF	;Reseteamos la bandera de Carry del Tmr0 
    return
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bcf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 250KHz
    return
 ;delay_big:
    ;movlw	50		;valor inical del contador 
    ;movwf	cont+1
    ;call	delay_small	;rutina de delay
    ;decfsz	cont+1, 1	;decrementar el contador 
    ;goto	$-2		;ejecutar dos líneas atrás
    ;return
    
 ;delay_small:
    ;movlw	150		;valor incial
    ;movwf	cont
    ;decfsz	cont, 1		;decrementar
    ;goto	$-1		;ejecutar línea anterior
    ;return
end
