; Documento: Proyecto 1 - Microcontroladores 
; Dispositivo: PIC16F887
; Autor: Juan Antonio Peneleu Vásquez 
; Programa: semaforo
; Creado: 20 Marzo, 2021
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

 MODO	EQU 0		//Push Bottons Modo
 INC	EQU 1		//Push Botton de incrementar
 DECRE	EQU 2		//Push Botton de decrementar
	
reiniciar_Tmr0 macro	//macro
    banksel TMR0	//Banco de TMR0
    movlw   25		//Movemos valor de tmr0  4 ms
    movwf   TMR0        //Movemos valor de tmr0
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
    movlw   244		//valor para 250 ms 
    movwf   PR2		//Mover valor a PR2
    
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
    centena:	DS  1	;semaforo1
    centena1:	DS  1
    decena:	DS  1
    decena1:	DS  1
    unidad1:	DS  1
    unidad:	DS  1  
    valor_actual:   DS	1
    V2:		DS  1	;configsemaforo123
    centena2:	DS  1
    centena22:	DS  1
    decena2:	DS  1
    decena22:	DS  1
    unidad2:	DS  1
    unidad22:	DS  1  
    V3:		DS  1	;semaforo2
    centena3:	DS  1
    centena33:	DS  1
    decena3:	DS  1
    decena33:	DS  1
    unidad3:	DS  1
    unidad33:	DS  1     
    V4: 	DS  1	;semaforo3
    centena4:	DS  1
    centena44:	DS  1
    decena4:	DS  1
    decena44:	DS  1
    unidad4:	DS  1
    unidad44:	DS  1  
    V1:		DS  1	;Variables para configuración semaforo1
    Tmr0_temporal:   DS	1	
    T0_Actual:	    DS	1   
    SE2_temporal:   DS	1   ;Variables para configuración semaforo2
    SE2_Actual:	    DS	1  
    SE3_temporal:   DS	1   ;;Variables para configuración semaforo3
    SE3_Actual:	    DS	1  
    estado:	DS  1
    valorsemaforo_1: DS	1
    semaforo1:	DS 1
    display_semaforo1:	DS  1
    valor_titileo: DS 1
    semaforo2:  DS 1
    semaforo3:  DS 1
    
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
    movf    w_temp	    //mover f(w_temp) a w
    swapf   STATUS, W	    //Intercambiar los nibles del status y guardar en w
    movwf   STATUS_TEMP	    //Mover el STATUS intercambiado a Status temporal
    movf    PCLATH, W	    //Mover PCLATH a una variable temporal 
    movwf   PCLATH_TEMP
  isr:
    btfsc   RBIF	    //Revisamos bandera de interrupción IOC
    call    int_ioCB	    //Llamamos a subrutina de interrupción IOCB
    
    btfsc   T0IF	    //Revisamos bandera de interrupción Tmr0
    call    Interr_Tmr0	    //llamamos a subrutina de interrupción de tmr0
    
    btfsc   TMR2IF	    //Revisamos bandera de tmr2
    call    Interr_Tmr2	    //llamamos a subrutina de interrupción de tmr2
  pop:
    movf    PCLATH_TEMP, W
    movwf   PCLATH	    //regresamos la variable temporal al PCLATH original
    swapf   STATUS_TEMP, W
    movwf   STATUS	    //Intercambiamos nibles y regresamos a STATUS
    swapf   w_temp, F
    swapf   w_temp, W
    retfie
;---------SubrutinasInterrupción-----------
Interr_Tmr0:
    reiniciar_Tmr0		;2 ms
    bcf	    STATUS, 0		;limpiar bandera de carry del status
    clrf    PORTD		;limpiar PORTD para activación de transistores 
    btfsc   banderas, 0		;Revisar bit 0 de banderas
    goto    displayunidad	;Llamar a subrutina de displayunidad semaforo1	    ;
    btfsc   banderas, 1		;Revisar bit 1 de banderas
    goto    displaydecena	;Llamar a subrutina de displaydecena semaforo2
    btfsc   banderas, 2		;Revisar bit 2 de banderas
    goto    displayunidad_SE1   ;display unidad de configuración de semaforos
    btfsc   banderas, 3		;Revisar bit 3 de banderas
    goto    displaydecen_SE1    ;display decena de configuración de semaforos
    
    btfsc   banderas, 4		;Revisar bit 4 de banderas
    goto    displayunidad_SE3   ;Llamar a subrutina de displayunidad semaforo2
    btfsc   banderas, 5		;Revisar bit 5 de banderas
    goto    displaydecen_SE3   ;Llamar a subrutina de displaydecena semaforo2
    btfsc   banderas, 6		;Revisar bit 6 de banderas
    goto    displayunidad_SE4   ;Llamar a subrutina de displayunidad semaforo3
    btfsc   banderas, 7		;Revisar bit 7 de banderas
    goto    displaydecen_SE4   ;Llamar a subrutina de displaydecena semaforo3
    movlw   00000001B		
    movwf   banderas		;mover literal a variable banderas

Verificaciones:			//subrutina de verificación para titileo y amarillo
    movlw   4			//resta entre el valor del semaforo3 y 4
    subwf   semaforo3, 0	//revisamos el carry cuando se levanta es positivo
    btfss   STATUS, 0		//carry es 0 cuando la resta es negativa entonces ejecutamos linea siguiente
    goto    amarillo_semaforo3	//subrutina de amarillo semaforo3
    movlw   7	    
    subwf   semaforo3, 0	//restamos el valor de semaforo3 con 7
    btfss   STATUS, 0		//cuando el carry es 0 la resta es negativa
    goto    RUTINA_TITILEO3	//subrutina de titileo para semaforo3
    
    call    tit2		//subrutina de verificación para semaforo2
    
    movlw   4			//resta entre el valor del semaforo1 y 4
    subwf   semaforo1, 0	
    btfss   STATUS, 0		//cuando el carry es 0 la resta es negativa
    goto    amarillo_semaforo1	//subrutina de amarillo semaforo1
    movlw   7
    subwf   semaforo1,0		//restamos el valor de semaforo1 con 7
    btfss   STATUS, 0		//cuando el carry es 0 la resta es negativa
    goto    RUTINA_TITILEO1	//subrutina de titileo para semaforo1
    return
tit2:
    movlw   4
    subwf   semaforo2, 0	//Guarda en w
    btfss   STATUS, 0		//resta entre el valor del semaforo2 y 4
    goto    amarillo_semaforo2	//subrutina de amarillo semaforo2
    movlw   7
    subwf   semaforo2,0		//restamos el valor de semaforo1 con 7
    btfss   STATUS, 0		//cuando el carry es 0 la resta es negativa
    goto    RUTINA_TITILEO2	//subrutina de titileo para semaforo2
    return
    
RUTINA_TITILEO1:
    btfss   valor_titileo,0	//revisar si es 1 bit0 de variable a 250ms de cambio
    goto    DISP_OFF		//si es 0 llama a subrutina donde se apaga led verde
    bsf     PORTA,0		//si es 1 encendemos led verde de semaforo1
    return
    
RUTINA_TITILEO2:
    btfss   valor_titileo,0	//revisar si es 1 bit0 de variable a 250ms de cambio
    goto    DISP_OFF		//si es 0 llama a subrutina donde se apaga led verde
    bsf     PORTA,3		//si es 1 encendemos led verde de semaforo2
    return
RUTINA_TITILEO3:
    btfss   valor_titileo,0	//revisar si es 1 bit0 de variable a 250ms de cambio
    goto    DISP_OFF		//si es 0 llama a subrutina donde se apaga led verde
    bsf     PORTA, 6		//si es 1 encendemos led verde de semaforo3
    bcf	    PORTA, 3		//apagamos led verde de semaforo2
    return
    
DISP_OFF:			//Subrutina para apgar leds verde en titileo
    bcf     PORTA, 0
    bcf	    PORTA, 3
    bcf	    PORTA, 6 
    RETURN

amarillo_semaforo1:
    bcf	    PORTA, 0		//apagamos los otros leds del semaforo1
    bsf	    PORTA, 1		//encendemos led amarillo semaforo1
    bcf	    PORTA, 2		
    movlw   0			
    subwf   semaforo1, 0	//resta de semaforo1 con 0
    btfsc   STATUS, 2		//cuando semaforo1 es cero se levanta la bandera zero
    goto    rojoSE1		//cuando se llega a 0 se llama a surutina de led rojo
    return
rojoSE1:
    bcf	    PORTA, 1		//prender rojo y apagar amarillo
    bsf	    PORTA, 2		//para semaforo1
    return   
amarillo_semaforo2:
    bcf	    PORTA, 3		//apagamos los otros leds del semaforo2
    bsf	    PORTA, 4		//encendemos led amarillo semaforo2
    bcf	    PORTA, 5
    movlw   0			
    subwf   semaforo2, 0	//resta de semaforo2 con 0
    btfsc   STATUS, 2		//cuando semaforo2 es cero se levanta la bandera zero
    goto    rojoSE2		//cuando se llega a 0 se llama a surutina de led rojo
    return
rojoSE2:
    bcf	    PORTA, 4		//prender rojo y apagar amarillo
    bsf	    PORTA, 5		//para semaforo2
    return      
amarillo_semaforo3:
    bcf	    PORTA, 3
    bcf	    PORTA, 6		//apagamos los otros leds del semaforo3
    bsf	    PORTA, 7		//encendemos led amarillo semaforo3
    bcf	    PORTB, 7
    movlw   0			
    subwf   semaforo3, 0	//resta de semaforo3 con 0
    btfsc   STATUS, 2		//cuando semaforo2 es cero se levanta la bandera zero
    goto    rojoSE3		//cuando se llega a 0 se llama a surutina de led rojo
    return
rojoSE3:
    bcf	    PORTA, 6		//prender rojo y apagar amarillo
    bcf	    PORTA, 7		//para semaforo3
    return      
   
displayunidad_SE1:	    //Display de configuraciones
    movlw   00001000B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    unidad22, w	    //Mover el valor de unidad22 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 7	    //Encender bit7 de PORTD para transistor 
    goto    Verificaciones
displaydecen_SE1:	    //Display de configuraciones
    movlw   00010000B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    decena22, w	    //Mover el valor de decena22 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 6	    //Encender bit6 de PORTD para transistor 
    goto    Verificaciones
displaydecena:		    //Semaforo1
    movlw   00000100B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    decena1, w	    //Mover el valor de decena1(Tabla) a w
    movwf   PORTC	    //Mover el valor de w a PORTC
    bsf	    PORTD, 0	    //Encender bit 0 PORTD para transistor
    goto    Verificaciones	
displayunidad:		    //Semaforo1
    movlw   00000010B		
    movwf   banderas	    //Se carga valor literal a banderas para otro display	
    movf    unidad1, w	    //Mover el valor de Unidad1(Tabla) a w
    movwf   PORTC	    //mover el valor de w a PORTD
    bsf	    PORTD, 1	    //Encender bit 1 de PORTD para transistor
    goto    Verificaciones	
    
displayunidad_SE3:	    //semaforo2
    movlw   00100000B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    unidad33, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 3	    //Encender bit3 de PORTD para transistor 
    goto    Verificaciones
displaydecen_SE3:	    //semaforo2
    movlw   01000000B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    decena33, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 2	    //Encender bit2 de PORTD para transistor 
    goto    Verificaciones    
    
displayunidad_SE4:	    //semaforo3
    movlw   10000000B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    unidad44, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 5	//Encender bit5 de PORTD para transistor    
    goto    Verificaciones
displaydecen_SE4:	    //semaforo3
    movlw   00000001B
    movwf   banderas	    //Se carga valor literal a banderas para otro display
    movf    decena44, w	    //Mover el valor de centena1 (Tabla) a w
    movwf   PORTC	    //Mover w a PORTC
    bsf	    PORTD, 4	    //Encender bit4 de PORTD para transistor 
    movlw   0x00
    movwf   banderas	    ;Mover literal a banderas
    goto    Verificaciones    
        
;----Estados-Interrupciones--------------------------
int_ioCB:			//subrutina de interrupcion iocb
    movf    estado, W		//variable estado a w 
    clrf    PCLATH		//limpiamos PCLAth 
    andlw   0x07		//Literal para posiciones en PC
    addwf   PCL			//añadimos a PCL
    goto    interrup_estado_0	//se llama a la interrupción del primer estado
    goto    interrup_estado_1	//se llama a la interrupción del segundo estado
    goto    interrup_estado_2	//se llama a la interrupción del tercer estado
    goto    interrup_estado_3	//se llama a la interrupción del cuarto estado
    goto    interrup_estado_4	//se llama a la interrupción del quinto estado
    goto    finalIOC		//las posiciones restantes no la usaremos
    goto    finalIOC		//llamamos a la subrutina donde resetea la interrupción 
 interrup_estado_0:		//Modo funcionamiento normal
    banksel PORTB
    bcf     PORTA,1
    bsf     PORTA,0		    
    btfsc   PORTB, MODO		//revisamos boton de modo
    goto    finalIOC		//subrutina de final de interrupción 
    incf    estado		//incrementa variable estado para pasar a siguiente estado
    movf    T0_Actual, W	//Valor actual de semaforo1 se pasa a 
    movwf   Tmr0_temporal	//variable temporal para su configuracion
    movf    SE2_Actual, w	//Valor actual de semaforo2 se pasa a
    movwf   SE2_temporal	//variable temporal para su configuracion
    movf    SE3_Actual, w	//Valor actual de semaforo3 se pasa a
    movwf   SE3_temporal	//variable temporal para su configuracion
    goto    finalIOC
 
 interrup_estado_1:		//configuración semaforo1
    btfss   PORTB, INC		//se revisa el boton incrementar
    incf    Tmr0_temporal, 1	//se incrementa la variable temporal y se guarda en el misma variable 
    movlw   21			//se realiza a una resta para establecer cuando
    subwf   Tmr0_temporal, 0	//se pase de 20 
    btfsc   STATUS, 2		//se verifica la bandera zero 
    goto    valor_minSemaforo1	//se llama a subrutina que modifica el valor temporal 
    
    btfss   PORTB, DECRE	//se revisa el boton decrementar
    decf    Tmr0_temporal, 1	//se decrementa la variable temporal y se guarda en el misma variable
    movlw   9			//se realiza a una resta para establecer cuando
    subwf   Tmr0_temporal, 0	//se decremente y se pase de 10
    btfsc   STATUS, 2		//se verifica la bandera zero
    goto    valor_maxSemaforo1	//se llama a subrutina que modifica el valor temporal
    
    btfss   PORTB, MODO		//revisamos boton de modo
    incf    estado		//incrementamos valor de variable pasar a otro estado
    goto    finalIOC		//subrutina para reset de interrupción 
 interrup_estado_2:		//configuracion semaforo2
    btfss   PORTB, INC
    incf    SE2_temporal, 1   
    movlw   21
    subwf   SE2_temporal, 0
    btfsc   STATUS, 2
    goto    valor_minSemaforo2
    
    btfss   PORTB, DECRE
    decf    SE2_temporal, 1
    movlw   9
    subwf   SE2_temporal, 0
    btfsc   STATUS, 2
    goto    valor_maxSemaforo2
    
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC
 interrup_estado_3:		//configuracion semaforo3
    btfss   PORTB, INC
    incf    SE3_temporal, 1   
    movlw   21
    subwf   SE3_temporal, 0
    btfsc   STATUS, 2
    goto    valor_minSemaforo3
    
    btfss   PORTB, DECRE
    decf    SE3_temporal, 1
    movlw   9
    subwf   SE3_temporal, 0
    btfsc   STATUS, 2
    goto    valor_maxSemaforo3
    
    btfss   PORTB, MODO
    incf    estado
    goto    finalIOC
 interrup_estado_4:		//modo de desicion 
    btfss   PORTB, MODO		//revisamos boton de modo
    goto    comienzo_estado	//llamamos a subrutina cuando se suelte el boton (antirebote)
    btfss   PORTB, DECRE	//revisamos boton de decrementar
    clrf    estado		//limpiamos variable para que vuelva al primer estado sin hacer modificaciones 
    btfsc   PORTB, INC		//revisamos boton de incrementar
    goto    finalIOC2		//subrutina de reset de interrupción 
				//si el boton de incrementar esta presionado
    movf    Tmr0_temporal, W	//todas las variables temporales     
    movwf   T0_Actual		//se pasan a la actual 
    movf    T0_Actual, W	//Valores actuales se cargan en las variables de conteo
    movwf   semaforo1		//de cada semaforo
    
    movf    SE2_temporal, W	
    movwf   SE2_Actual		//variable configurada
    movf    SE2_Actual, W	//se cargan en las variables de conteo de semaforo2
    movwf   semaforo2 
    
    movf    SE3_temporal, W
    movwf   SE3_Actual		//variable configurada
    movf    SE3_Actual, W	//se cargan en las variables de conteo de semaforo3
    movwf   semaforo3
    clrf    estado
 finalIOC:			//subrutina para reset interrupcion iocb
    bcf	    RBIF
    return
 finalIOC2:		//subrutina para boton inc en el ultimo estado
    clrf    PORTA	//asignamos a PORTA los valores para encender leds en rojo 
    bsf	    PORTA, 5
    bsf	    PORTB, 7
    bcf	    RBIF
    return
comienzo_estado:	//subrutina push Modo ultimo
    movlw   0x00	//limpiamos variable estado
    movwf   estado	//para que regrese a primer estado
    goto    finalIOC
valor_minSemaforo1:
    movlw   10		    //se le asigna el valor de 10 a variable temporal
    movwf   Tmr0_temporal   //cuando se pase de 20
    bcf	    RBIF
    return
valor_maxSemaforo1:
    movlw   20		    //se asigna 20 a variable temporal 
    movwf   Tmr0_temporal   //cuando decremente despues de 10
    bcf	    RBIF
    return
valor_minSemaforo2:
    movlw   10		    //se le asigna el valor de 10 a variable temporal
    movwf   SE2_temporal    //cuando se pase de 20
    bcf	    RBIF
    return
valor_maxSemaforo2:
    movlw   20		    //se asigna 20 a variable temporal
    movwf   SE2_temporal    //cuando decremente despues de 10
    bcf	    RBIF
    return
valor_minSemaforo3:
    movlw   10		    //se le asigna el valor de 10 a variable temporal
    movwf   SE3_temporal    //cuando se pase de 20
    bcf	    RBIF
    return
valor_maxSemaforo3:
    movlw   20		    //se asigna 20 a variable temporal
    movwf   SE3_temporal    //cuando decremente despues de 10
    bcf	    RBIF
    return
    
Interr_Tmr2:		    //subrutina interrupción tmr2
    bcf    TMR2IF	    //limpiamos bandera de interrupción
    incf   valor_titileo    //incrementamos variable para titileo a 250ms 
    return
    
  PSECT code, delta=2, abs
  ORG 180h	;Posición para el código
 ;------------------ TABLA -----------------------
  Tabla:
    clrf  PCLATH		    //limpiamos PCLATH 
    bsf   PCLATH,0		    //habilitamos el PCLATH 
    andlw 0x0F			    //Añadimos los espacios para los valores del displays 
    addwf PCL			    //de cero hasta F
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
    call    config_io		//configuracion de entradas y salidas 
    call    config_reloj	//configuración reloj interno
    call    config_IOChange	//configuración de interrupcion OC
    call    config_tmr0		//configuración tmr0
    call    config_tmr1		//configuración tmr1
    call    config_tmr2		//configuración tmr2
    call    config_InterrupEnable  //configuración interrupciones 
    banksel PORTA 
    clrf    estado		//limpiamos variable estado para que comience en el primer estado
    movlw   0x0A
    movwf   T0_Actual		//asignamos valor inicial
    movf    T0_Actual, W	//a semaforo1
    movwf   semaforo1
    movlw   0x0A
    movwf   SE2_Actual		//asignamos valor inicial
    movf    SE2_Actual, W	//a semaforo2
    movwf   semaforo2
    movlw   0x0A
    movwf   SE3_Actual		//asignamos valor inicial
    movf    SE3_Actual, W	//a semaforo3
    movwf   semaforo3
    bsf	    PORTA, 0		//encendemos leds correspondiente a semaforo1
    bsf	    PORTA, 5
    bsf	    PORTB, 7
;----------loop principal---------------------
 loop:			    //funcionamiento continuo de semaforos
    btfss   TMR1IF	    //revisamos bandera de overflow tmr1
    goto    $-1		    //regresa una linea hasta que se levante
    reiniciar_Tmr1	    //reinicio ocurre cuando bandera se activa cada 1 segundo
    call    INICIO_SEMAFORO1   //llamamos a subrutina que contiene todo el funcionamiento	
 
    bcf	    GIE
    movf    estado, w	    //Movemos estado a w para que PCLATH lo lea
    clrf    PCLATH
    bsf	    PCLATH, 0	    //habilitamos PCLATH
    andlw   0x07	    //Literal con valor de bits necesarios para los modos
    addwf   PCL		    //se añaden en en el PCL
    goto    estado_0	    //subrutina estados
    goto    estado_1
    goto    estado_2
    goto    estado_3
    goto    estado_4
    goto    loop	    //no usaremos 
    goto    loop
 estado_0:
    bsf	    GIE  
    movlw   000B
    movwf   PORTE		//encendemos leds correspondientes a este modo
    goto    loop    ;loop forever
 estado_1:
    bsf	    GIE
    movf    Tmr0_temporal, w	 //movemos valor temporal de semaforo 1 a
    movwf   V2			//variable de división para displays en decimal 
    call    divcentenas_SE1	//Subrutina de división para contador DECIMAL 
    call    displaydecimal_SE1	//subrutina para asignación de valor de tabla para displays
    movlw   001B		//encendemos leds correspondientes a este modo
    movwf   PORTE
    goto    loop
 estado_2:
    bsf	    GIE
    movf    SE2_temporal, w	//movemos valor temporal de semaforo 2 a
    movwf   V2			//variable de división para displays en decimal
    call    divcentenas_SE1	//Subrutina de división para contador DECIMAL 
    call    displaydecimal_SE1	//subrutina para asignación de valor de tabla para displays
    movlw   010B		//encendemos leds correspondientes a este modo
    movwf   PORTE
    goto    loop
 estado_3:
    bsf	    GIE			
    movf    SE3_temporal, w	//movemos valor temporal de semaforo 2 a
    movwf   V2			//variable de división para displays en decimal
    call    divcentenas_SE1	//Subrutina de división para contador DECIMAL 
    call    displaydecimal_SE1	//subrutina para asignación de valor de tabla para displays
    movlw   011B		//encendemos leds correspondientes a este modo
    movwf   PORTE
    goto    loop
 estado_4:
    bsf	    GIE
    movlw   100B
    movwf   PORTE		//encendemos leds correspondientes a este modo
    goto    loop
;------------sub rutinas---------------------
INICIO_SEMAFORO1:   
    movf    semaforo1, w	
    addwf   V4
    movf    SE2_Actual, w	//sumamos valor de semaforo1 y semaforo 2 a
    addwf   V4			//variable de display para semaforo3
    call    divcentenas_SE4	//división para valor decimal
    call    displaydecimal_SE4	//valor de tabla para displays
    
    movlw   0x00
    subwf   semaforo1		//resta para semaforo1 cuando llega a 0
    btfsc   STATUS, 2		//revisar bander de zero
    goto    INICIO_SEMAFORO2	//cuando llegue a cero semaforo1, llamamos a inicio semaforo2
    decf    semaforo1		//decrementamos semaforo1 a 1 segundo
   
    movf    semaforo1, w    
    movwf   V1			//variable para displays de semaforo1
    movwf   V3			//variable para displays de semaforo2
    call    divcentenas		//subrutina para division y obtener valor decimal
    call    displaydecimal	//asignar valor de tabla 
    call    divcentenas_SE3	//subrutina para division y obtener valor decimal
    call    displaydecimal_SE3	//asignar valor de tabla
    
    return 
INICIO_SEMAFORO2:
    movf    semaforo2, w
    addwf   V1
    movf    SE3_Actual, w	//sumamos valor de semaforo2 y semaforo 3 a
    addwf   V1			//variable para displays de semaforo1
    call    divcentenas	
    call    displaydecimal
    
    bsf	    PORTA, 3	;verdeSE2
    bcf	    PORTA, 5	;Rojo SE2
    bsf	    PORTB, 7	;Rojo SE3
    clrf    semaforo1		//reset semaforo1 para que nos mantengamos en esta subrutina 
    movlw   0x00		//resta para saber si semaforo2 llego a 0
    subwf   semaforo2
    btfsc   STATUS, 2		//bandera zero revisar
    goto    INICIO_SEMAFORO3	//Cuando llegue a cero semaforo2 llamamos a inicio semaforo3
    decf    semaforo2		//decrementamos valor de semaforo2
    
    movf    semaforo2, w    ;Displays semaforo2
    movwf   V3
    movwf   V4		    ;display semaforo3
    call    divcentenas_SE3	
    call    displaydecimal_SE3
    call    divcentenas_SE4	
    call    displaydecimal_SE4

    return
INICIO_SEMAFORO3:
    movf    semaforo3, w
    addwf   V3
    movf    SE2_Actual, w	//sumamos valor de semaforo1 y semaforo 3 a
    addwf   V3			//variable para displays semaforo2
    call    divcentenas_SE3	
    call    displaydecimal_SE3
    
    bsf	    PORTA, 6		//encendemos leds correspondientes a este semaforo
    bsf	    PORTA, 2
    bsf	    PORTA, 5
    bcf     PORTB, 7
    clrf    semaforo2
    movlw   0x00		
    subwf   semaforo3		//revisar si semaforo 3 llego a cero von resta
    btfsc   STATUS, 2		//revisar bandera zero
    goto    asignarvalor	//si llego a cero semaforo 3 llamamos a subrutina para asignar nuevamente los valores 
    decf    semaforo3		//decrementamos cada segundo semaforo3
    
    movf    semaforo3, w    ;Displays semaforo3 
    movwf   V4		    
    movwf   V1		    //variable displays para semaforo1
    call    divcentenas_SE4
    call    displaydecimal_SE4
    call    divcentenas	
    call    displaydecimal
    
    return 
asignarvalor:
    movf    T0_Actual, W	//asignamos los valores nuevamente a cada una de las variables
    movwf   semaforo1		//para semaforo1
    movf    SE2_Actual, W
    movwf   semaforo2		//para semaforo2
    movf    SE3_Actual, W
    movwf   semaforo3		//para semaforo3
    movlw   00100001B		//encendemos leds de comienzo de rutina de semaforos
    movwf   PORTA
    bsf	    PORTB, 7
    return

;------------------DivisiónRutinaPrincipal-------------------
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
    
;---------------------------RutinaSemaforo1---------------------------
displaydecimal_SE1:
    movf    centena2, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena22	//Lo guardamos en variable centena1
    movf    decena2, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena22	//Lo guardamos en variable decena1
    movf    unidad2, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad22	//Lo guardamos en variable unidad1
    return
divcentenas_SE1:
    clrf    centena2	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V2, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS_SE1	 //llama a subrutina para resta en decena
    incf    centena2, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS_SE1:
    clrf    decena2	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V2		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V2,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES_SE1	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena2, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES_SE1:
    clrf    unidad2	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V2		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V2,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad2, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad 
;------------------------------------------------------------------------------------
    
    
displaydecimal_SE3:
    movf    centena3, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena33	//Lo guardamos en variable centena1
    movf    decena3, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena33	//Lo guardamos en variable decena1
    movf    unidad3, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad33	//Lo guardamos en variable unidad1
    return
divcentenas_SE3:
    clrf    centena3	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V3, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS_SE3	 //llama a subrutina para resta en decena
    incf    centena3, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS_SE3:
    clrf    decena3	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V3		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V3,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES_SE3	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena3, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES_SE3:
    clrf    unidad3	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V3		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V3,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad3, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad    
    
;--------------------------------------------------------------------------------
    
displaydecimal_SE4:
    movf    centena4, w
    call    Tabla   //Asignamos el valor de centena a un valor de la tabla displays
    movwf   centena44	//Lo guardamos en variable centena1
    movf    decena4, w	
    call    Tabla   //Asignamos el valor de decena a un valor de la tabla displays
    movwf   decena44	//Lo guardamos en variable decena1
    movf    unidad4, w
    call    Tabla   //Asignamos el valor de unidad a un valor de la tabla displays
    movwf   unidad44	//Lo guardamos en variable unidad1
    return
divcentenas_SE4:
    clrf    centena4	 //Limpiamos la variable centena 
    movlw   01100100B    //asignamos EL VALOR DE "100" W
    subwf   V4, 1	 //resta f DE w(ValorPORTA-100) y guardamos de nuevo en V1
    btfss   STATUS,0	 //Revisamos bandera de carry de Status (Indica un cambio de signo en la resta)
    goto    DECENAS_SE4	 //llama a subrutina para resta en decena
    incf    centena4, 1	 //Incrementa el valor de centena y se guarda en ella misma
    goto    $-5		 //Regresa 5 líneas atras y resta nuevamente 
DECENAS_SE4:
    clrf    decena4	//Limpiamo variable decena
    movlw   01100100B	 
    addwf   V4		//Sumamos 100 a V1 (Para que sea el valor ultimo correcto)
    movlw   00001010B	//Valor de 10 a w   
    subwf   V4,1	//Restamos f-w (V1-10) guardamos en V1
    btfss   STATUS,0	//Revisamo bit de carry Status
    goto    UNIDADES_SE4	//Llama a subrutina UNIDADES si hay un cambio de signo en la resta
    incf    decena4, 1	//Incrementa variable decena 
    goto    $-5		//Ejecuta resta en decenas 
UNIDADES_SE4:
    clrf    unidad4	//Limpiamos variable unidad
    movlw   00001010B	
    addwf   V4		//Sumamos 10 a V1(Valor ultimo correcto)
    movlw   00000001B	//Valor de 1 a w
    subwf   V4,1	//Restamos f-w y guardamos en V1
    btfss   STATUS, 0	//Revisar bit carry de status
    return		//Return a donde fue llamado
    incf    unidad4, 1	//Incrementar variable unidad
    goto    $-5		//Ejecutar de nuevo resta de unidad    
;-------------------------------------------------------------------------------    
config_IOChange:
    banksel TRISA
    bsf	    IOCB, MODO
    bsf	    IOCB, INC
    bsf	    IOCB, DECRE
    
    banksel PORTA
    movf    PORTB, W	;Condición mismatch
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
    clrf    TRISE
    movlw   00000111B
    movwf   TRISB

    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, MODO
    bsf	    WPUB, INC
    bsf	    WPUB, DECRE
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6	;Banksel PORTA
    clrf    PORTA	;Valor incial 0 en puerto A
    clrf    PORTC
    clrf    PORTB
    clrf    PORTD
    return
    
 config_tmr0:
    banksel OPTION_REG   ;Banco de registros asociadas al puerto A
    bcf	    T0CS    ; reloj interno clock selection
    bcf	    PSA	    ;Prescaler 
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0	    ;PS = 111 Tiempo en ejecutar , 256
    
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
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bcf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 1Mhz
    return
    

config_InterrupEnable:
    BANKSEL PIE1
    bsf	    T0IE	;Habilitar bit de interrupción tmr0
    bsf     TMR2IE
    BANKSEL T1CON 
    bsf	    GIE		;Habilitar en general las interrupciones, Globales
    bsf	    RBIE	;Se encuentran en INTCON
    bcf	    RBIF	;Limpiamos bandera de IOC
    bcf	    T0IF	;Limpiamos bandera de overflow de tmr0
    bcf     TMR2IF	;Limpiamos bandera de overflow de tmr2
    return
 
end
