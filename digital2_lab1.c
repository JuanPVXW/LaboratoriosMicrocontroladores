/*
 * File:   Lab01Digital.c
 * Author: acer
 *
 * Created on 16 de julio de 2021, 12:05 AM
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
#define _XTAL_FREQ 4000000
//*****IMPORTACION DE LIBRERIAS******
#include <xc.h>
#include <stdint.h>
#include <pic16f887.h>
#include "converADC.h"
uint8_t contador = 0;       /*Declaración variables*/
uint8_t var1 = 0;
uint8_t hex1 = 0;
uint8_t hex2 = 0;
int unidades;
int decenas = 0;
int centenas = 0;
int banderas = 0;
int v1;
//***********Prototipos de funciones************
void setup(void);           /*funcion principal */
int tabla(int v1);          /*Tabla para displays*/
//**************Interrupciones**************
void __interrupt()isr(void) /*interrupciones*/
{
    //if (PIR1bits.ADIF == 1)
    //{
        //var1 = ADRESH;
    //}
    recibir_valoresADC();
    PIR1bits.ADIF = 0;
    if(RBIF == 1)
    {
        if(RB0 == 0)
        {
            PORTA++;
        }
        if(RB1 == 0)
        {
            PORTA--;
        }
    }
    INTCONbits.RBIF = 0;
    if (T0IF == 1)              /*condicion si T0IF es 1*/
    {
        PORTC = 0;              /*Limpiar PORTC*/
        TMR0 = 236;             /*Asignar valor a registro TMR0*/
        T0IF = 0;               /*Limpiar bandera de interrupción*/
        if (banderas == 0)      /*condicion si banderas es 0*/
        {
            v1 = hex1;      /*asignar unidades a v1 para asignar tabla*/
            PORTD = tabla(v1);  /*valor de tabla a PORTD*/
            RC0 = 1;            /*Enceder transistor para displays*/
            banderas = 1;       /*Asignar valor a banderas*/
            return;             /*regresa a condicion*/
        }
        if (banderas == 1)      /*condicion si banderas es 1*/
        {
            v1 = hex2;       /*asignar decenas a v1 para asignar tabla*/
            PORTD = tabla(v1);  /*valor de tabla a PORTD*/
            RC1 = 1;            /*Enceder transistor para displays*/
            banderas = 0;       /*Asignar valor a banderas*/
            return; 
        }
    }
}
//*********************************funcionPrincipal**********
void main(void) {
    setup();                /*funcion de configuracion principal*/
    __delay_us(50);
    ADCON0bits.GO = 1;
    //*********************************LoopPrincipal*********
    while(1)
    {
        hex1 = var1 & 0x0F;
        hex2 = (var1>>4) & 0x0F;
        //if(ADCON0bits.GO == 0)
        //{
            //__delay_us(50);
        //}
        //ADCON0bits.GO = 1;
        inicio_conversionADC();
        
        if(var1 >= PORTA)
        {
            RC7 = 1;
        }
        else
        {
            RC7 = 0;
        }
    }
}
//*************Funciones************************
int tabla (int v1)          /*funcion tabla para displays*/
{
 int w;                     /*declarar variable interna*/
 switch (v1)
 {
     case 0 :               /*Caso*/
         w = 0b00111111;    /*valor para display*/
         break; 
     case 1 :               /*Caso*/
         w = 0b00000110;    /*valor para display*/
         break;
     case 2 :               /*Caso*/
         w = 0b01011011;    /*valor para display*/
         break;
     case 3 :               /*Caso*/
         w = 0b01001111;    /*valor para display*/
         break;
     case 4 :               /*Caso*/
         w = 0b01100110;    /*valor para display*/
         break;
     case 5 :               /*Caso*/
         w = 0b01101101;    /*valor para display*/
         break;
     case 6 :               /*Caso*/
         w = 0b01111101;    /*valor para display*/
         break;
     case 7 :               /*Caso*/
         w = 0b00000111;    /*valor para display*/
         break;
     case 8 :               /*Caso*/
         w = 0b01111111;    /*valor para display*/
         break;
     case 9 :               /*Caso*/
         w = 0b01101111;    /*valor para display*/
         break;
     case 10 :               /*Caso*/
         w = 0b01110111;    /*valor para display*/
         break;
     case 11 :               /*Caso*/
         w = 0b01111100;    /*valor para display*/
         break;
     case 12 :               /*Caso*/
         w = 0b00111001;    /*valor para display*/
         break;
     case 13 :               /*Caso*/
         w = 0b01011110;    /*valor para display*/
         break;
     case 14 :               /*Caso*/
         w = 0b01111001;    /*valor para display*/
         break;
     case 15 :               /*Caso*/
         w = 0b01110001;    /*valor para display*/
         break;
     default : ; 
 }
 return w;
}
void setup(void)
{ 
    //*******configuración io entradas y salidas****
    ANSEL = 0b00100000;
    ANSELH = 0x00;     //Salidas Digitales
    
    TRISE = 0b001; 
    TRISC = 0x00; 
    TRISA = 0x00; 
    TRISB = 0x03; 
    TRISD = 0x00;    
    OPTION_REGbits.nRBPU = 0; 
    WPUB = 0b00000011;      //Habilitar Pull interno 
    
    PORTA = 0x00; 
    PORTC = 0x00; 
    PORTE = 0x00;
    PORTB = 0x00; 
    PORTD = 0X00;
    //configuración IOC
    IOCBbits. IOCB0 = 1; 
    IOCBbits. IOCB1 = 1;
    //configuración del reloj (oscilador interno)
    OSCCONbits. IRCF2 = 1; 
    OSCCONbits. IRCF1 = 1;
    OSCCONbits. IRCF0 = 0;  //4Mhz
    OSCCONbits. SCS = 1;
    //configuración Tmr0
    OPTION_REGbits. T0CS = 0;
    OPTION_REGbits. PSA = 0;
    OPTION_REGbits. PS2 = 1;    //Preescaler 
    OPTION_REGbits. PS1 = 1;
    OPTION_REGbits. PS0 = 1;
    
    //CONFIGURACIOS ADC
    ADCON1bits.ADFM = 0;        //justificado a la izquierda 
    ADCON1bits.VCFG0 = 0;       //Voltaje VDD referencia
    ADCON1bits.VCFG1 = 0;       //Voltaje Vss referencia
    
    ADCON0bits.ADCS = 1;        //ADC Clock FOSC/8
    ADCON0bits.CHS = 5;         //Canal 5
    __delay_us(100);
    ADCON0bits.ADON = 1;        //Habiliar Modulo de ADC
    //configuración interrupción
    INTCONbits. GIE = 1;
    INTCONbits. RBIE = 1;
    INTCONbits. RBIF = 0;
    INTCONbits.PEIE = 1;
    PIE1bits.ADIE = 1;
    PIR1bits.ADIF = 0;      
    INTCONbits. T0IE = 1;
    INTCONbits. T0IF = 0;
}
