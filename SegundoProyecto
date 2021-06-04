/*
 * File:   main9.c
 * Author: Juan Peneleu 15446
 *
 * 
 */
//Configuración PIC16F887
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (RCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, RC on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)
// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Progra
//****DirectivasCompliador*****//
#define _XTAL_FREQ 1000000
//*****IMPORTACION DE LIBRERIAS******
#include <xc.h>
#include <stdint.h>
#include <pic16f887.h>
/*Declaración variables*/
int unidades;
int decenas = 0;
int centenas = 0;
int banderas = 0;
int v1;
//***********Prototipos de funciones************
void setup(void);           /*funcion principal */
//**************Interrupciones**************
void __interrupt()isr(void) /*interrupciones*/
{
    if (PIR1bits. ADIF == 1)
    {
        if (ADCON0bits.CHS == 5)
        {
            CCPR1L = (ADRESH>>2) + 248; 
            CCP1CONbits.DC1B1 = ADRESH & 0b01; 
            CCP1CONbits.DC1B0 = ADRESL>>7;
        }
        else
        {
            CCPR2L   = (ADRESH>>2)+248 ;         //Aumentamos el Puerto C cuando se preciona el boton
            CCP2CONbits.DC2B1 = ADRESH & 0b01;
            CCP2CONbits.DC2B0 = (ADRESL>>7);
        }
            PIR1bits.ADIF = 0;
    }
}
//*********************************funcionPrincipal**********
void main(void) {
    setup();                /*funcion de configuracion principal*/
    __delay_us(50);
    ADCON0bits.GO = 1;          //comenzar conversión
    //*********************************LoopPrincipal*********
    while(1)
    {
        if (ADCON0bits.GO == 0)         //Si ya termino de convertir
        {
            if (ADCON0bits.CHS == 5)
            {
                ADCON0bits.CHS = 6;
            }
            else
            {
                ADCON0bits.CHS = 5;
            }
                __delay_us(50);             //Delay para los 11 ciclos de TAP 
                ADCON0bits.GO = 1;
        }    
    }
}
//*************Funciones************************
void setup(void)
{ 
    //*******configuración io entradas y salidas****
    ANSEL = 0b01100000;     //AN5 Y AN6
    ANSELH = 0x00;     //Salidas Digitales
    
    TRISE = 0x03; 
    TRISC = 0x00;      
    //OPTION_REGbits.nRBPU = 0; 
    //WPUB = 0b00000011;      //Habilitar Pull interno   
    PORTC = 0x00; 
    PORTE = 0x00;
    //configuración IOC
    //IOCBbits. IOCB0 = 1; 
    //IOCBbits. IOCB1 = 1;
    
    //configuración del reloj (oscilador interno)
    OSCCONbits. IRCF2 = 1; 
    OSCCONbits. IRCF1 = 0;
    OSCCONbits. IRCF0 = 0;  //1Mhz
    OSCCONbits. SCS = 1;
    //CONFIGURACIOS ADC
    ADCON1bits.ADFM = 0;        //justificado a la izquierda 
    ADCON1bits.VCFG0 = 0;       //Voltaje VDD referencia
    ADCON1bits.VCFG1 = 0;       //Voltaje Vss referencia
    
    ADCON0bits.ADCS = 0;        //ADC Clock FOSC/2
    ADCON0bits.CHS = 5;         //Canal 5 de inicio
    __delay_us(100);
    ADCON0bits.ADON = 1;        //Habiliar Modulo de ADC
    //***configuración PWM***
    TRISCbits.TRISC2 = 1;    // RC2/CCP1 encendido
    TRISCbits.TRISC1 = 1;    // RC1/CCP2 encendido
    
    PR2 = 165;               // Configurando el periodo
    CCP1CONbits.P1M = 0;     // Configurar el modo PWM
    
    CCP1CONbits.CCP1M = 0b1100;     //Modo PWM para pin CCP1
    CCP2CONbits.CCP2M = 0b1100;     //Modo PWM para pin CCP2
    
    CCPR1L = 0x0f;              //Definimos para valor inicial de Dutycicle
    CCPR2L = 0x0f;              //Definimos para valor inicial de Dutycicle
    
    CCP1CONbits.DC1B = 0;           //Bits menos significativos de ancho de pulso PWM
    CCP2CONbits.DC2B0 = 0;          //Valores inciales
    CCP2CONbits.DC2B1 = 0;
    
    PIR1bits.TMR2IF  =  0;
    T2CONbits.T2CKPS =  0b11;       //Preescaler 1:16
    T2CONbits.TMR2ON =  1;          //On Tmr2
    
    while(PIR1bits.TMR2IF  ==  0);  //Esperar un ciclo Tmr2
    PIR1bits.TMR2IF  =  0;          //Reset Bandera
    
    TRISCbits.TRISC2 = 0;           //Se resetean las salidas CCPx
    TRISCbits.TRISC1 = 0; 
    //configuración interrupción
    INTCONbits. GIE = 1; 
    INTCONbits.PEIE = 1;
    PIE1bits.ADIE = 1;
    PIR1bits.ADIF = 0;      
    //Limpiar bandera de ADC
    //INTCONbits. RBIE = 1;
    //INTCONbits. RBIF = 0;
} 
