; Documento:	Lab2
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: Contadodores Puerto A y B
; Creado: 13 febrereo, 2021
;-----------------------------------
PROCESSOR 16F887
#include <xc.inc>


; configuración word1
 CONFIG FOSC=XT //Oscilador externo Tipo XT
 CONFIG WDTE=OFF //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF   //pin MCLR se utiliza como I/O
 CONFIG CP=OFF	    //sin protección de código 
 CONFIG CPD=OFF	    //sin protección de datos 
 
 CONFIG BOREN=OFF   //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF   //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON	    //Programación en bajo voltaje permitida
 
;configuración word2
  CONFIG WRT=OFF	//Protección de autoescritura 
  CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 

;------------------------------
  PSECT udata_bank0 ;common memory
    cont:	DS  2 ;1 byte apartado
    ;cont_big:	DS  1;1 byte apartado
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	;posición 000h para el reset
  resetVec:
    PAGESEL main    ;Macro
    goto main
  
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
;---------configuración principal, entradas y salidas----------------------
 config_io:
    bsf	    STATUS, 5   ;banco  11
    bsf	    STATUS, 6
    clrf    ANSEL	;pines digitales
    clrf    ANSELH	
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6
    movlw   0xF0	;Movemos literal a F 11110000B
    movwf   TRISA	;bits menos significativos del puerto A como salidas
    movlw   0xF0
    movwf   TRISB	;bits menos significativos de puerto B como salidas
    movlw   11100000B
    movwf   TRISC

    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6
    movlw   0x00
    movwf   PORTA	;Valor incial 0 en puerto A
    movlw   0x00
    movwf   PORTB	;Valor incial 0 en puerto B
    movlw   0x00
    movwf   PORTC	;Valor incial 0 en puerto C
    return
;-----------------config-reloj-------------------------
 //config_reloj:
    //banksel OSCCON	;Banco OSCCON 
    //bcf	    IRCF2	;OSCCON configuración bit2 IRCF
    //bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    //bsf	    IRCF0	;OSCCON configuración bit0 IRCF
    //bsf	    SCS		;reloj interno 
    //return
;---------------configuración main------------------------------
  main: 
    call    config_io	    ;Llama a la configuración de entradas y salidas
    //call    config_reloj    ;Llama a la configuración del reloj 

    banksel PORTA  
;----------loop principal---------------------
 loop: 
    btfsc   PORTA, 4	;Cuando no este presionado 
    call    inc_porta
    btfsc   PORTA, 5	;Revisar si no esta presionado (Momento en que se suelta)
    call    dec_porta
    
    btfsc   PORTB, 4	;Revisar cuando no este presionado (Momento en que se suelta)
    call    inc_portb
    btfsc   PORTB, 5	;Revisar cuando no este presionado (Momento en que se suelta)
    call    dec_portb
    
    btfsc   PORTC, 5	;Revisar cuando no este presionado(Momento en que suelta)
    call    antirebote_suma
    
    btfsc   STATUS, 1	;Revisamos la bandera bit1 de STATUS
    bsf	    PORTC, 4	;Encendemos bit4 de PORTC
    
    btfss   STATUS, 1	;Revisamos bit1 de STATUS
    bcf	    PORTC, 4	;Encendemos bit4 de PORTC
    
    goto    loop    ;loop forever 
;------------sub rutinas----------------------------------
 inc_porta:
    call    delay_small	;Delay para la ejecución del boton
    btfsc   PORTA, 4	;Revisa que no este presionado ANTIREBOTE
    goto    $-1		;ejecuta una linea atrás	        
    incf    PORTA	;Incrementar PORTA
    return
 dec_porta:
    call    delay_small	;Delay para la ejecución del boton
    btfsc   PORTA, 5	;Revisa de nuevo si no esta presionado
    goto    $-1		;ejecuta una linea atrás	        
    decf    PORTA	;Decrementar PORTA
    return
 inc_portb:
    call    delay_small	;Delay para la ejecución del boton
    btfsc   PORTB, 4	;Revisa de nuevo si no esta presionado
    goto    $-1		;ejecuta una linea atrás	        
    incf    PORTB	;Incrementar PORTB
    return
 dec_portb: 
    call    delay_small
    btfsc   PORTB, 5	;Revisa de nuevo si no esta presionado
    goto    $-1		;ejecuta una linea atrás	        
    decf    PORTB	;Decrementar PORTB
    return
;--------------------SUMA-------------------------------
antirebote_suma:
    btfsc   PORTC, 5	    ;Revisamos cuando se deje de presionar el push en RC5
    goto    antirebote_suma ;Regresamos a ejecutar el inicio de la etiqueta
    call    sumar	    ;Llamamos a la etiqueta sumar para que se ejecute
    return
    
sumar:
    movf    PORTA, w	;El valor de PORTA lo guardamos en w
    addwf   PORTB, w	;Añadimos(suma) el valor de PORTB a w = PORTB + PORTA 
    movwf   PORTC	;Movemos el valor de w a PORTC (Resultado de suma)
    return 
;------------------delays------------------------   
 delay_big:
    movlw	50		;valor inical del contador 
    movwf	cont+1
    call	delay_small	;rutina de delay
    decfsz	cont+1, 1	;decrementar el contador 
    goto	$-2		;ejecutar dos líneas atrás
    return
    
 delay_small:
    movlw	150		;valor incial
    movwf	cont
    decfsz	cont, 1	;decrementar
    goto	$-1		;ejecutar línea anterior
    return
    
end


 