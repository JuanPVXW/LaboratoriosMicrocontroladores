/*
 * File:   main10.c
 * Author: Juan Peneleu 15446
 *
 * Created on 3 de mayo de 2021, 03:35 PM
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
/*Declaración variables*/
char data = 74; 
//***********Prototipos de funciones************
void setup(void);           /*funcion principal */
void Envio_caracter(char bt);
void cadena_caracteres(char st[]);
void Menuypreguntas(void);
//**************Interrupciones**************
void __interrupt()isr(void) /*interrupciones*/
{
    //if(PIR1bits.RCIF)           //Recibimiento de datos
    //{
        //PORTB = RCREG; 
    //}
}
//*********************************funcionPrincipal**********
void main(void) {
    setup();                /*funcion de configuracion principal*/
    __delay_ms(500);
    Menuypreguntas();       //menu
    //*********************************LoopPrincipal*********
    while(1)
    {
        while(!PIR1bits.RCIF);      //Espera a que se reciba un dato
        char var2 = RCREG;          //guardar dato recibido en var2
        //UART_send_char(rsp);
        if(var2 == 49)              //Si el caracter recibido es 1
        {
            cadena_caracteres("\rComo estas\r");    //desplegamos cadena
            Menuypreguntas();       //volvemos a mostrar menu 
        }
        if(var2 == 50)          //si el caracter recibido es 2
        {
            PORTA = 0;
            cadena_caracteres("\rIngrese un caracter para puerto A\r"); //desplegamos pregunta
            while(PIR1bits.RCIF == 0);          //Esperamos recibir dato 
            PORTA = RCREG;              //Mostrar dato recibido en puerto A
            Menuypreguntas();           //desplegamos menu 
        }
        if(var2 == 51)          //si el dato recibido es 3
        {
            PORTB = 0; 
            cadena_caracteres("\rIngrese un caracter para puerto B\r"); //desplegamos pregunta
            while(!PIR1bits.RCIF);      //esperamos recibir dato
            PORTB = RCREG;              //Mostrar dato recibido en Puerto B
            Menuypreguntas();           //Desplegamos menu 
        }
    }
}
//*************Funciones************************
void setup(void)
{ 
    //*******configuración io entradas y salidas****
    ANSEL = 0x00;     //Digitales
    ANSELH = 0x00;     //Salidas Digitales
    
    TRISA = 0x00;
    TRISB = 0x00;

    PORTB = 0x00;
    PORTA = 0x00;
    
    //configuración del reloj (oscilador interno)
    OSCCONbits. IRCF2 = 1; 
    OSCCONbits. IRCF1 = 1;
    OSCCONbits. IRCF0 = 0;  //4Mhz
    OSCCONbits. SCS = 1;
    //*****ConfiguraciónUART TX Y RX ***********
    TXSTAbits.SYNC = 0;             //Modo asíncrono
    TXSTAbits.BRGH = 1;             //Seleccion BAUD RATE
    BAUDCTLbits.BRG16 = 0; 
    
    SPBRG = 25;                     //Registros para valor BAUD RATE
    SPBRGH = 0; 
    
    RCSTAbits.SPEN = 1;         //Habilitar puerto serial asíncrono
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;         //Habilitar recepción de datos 

    TXSTAbits.TXEN = 1;         //Habilitar transmision
    
    //configuración interrupción
    //INTCONbits. GIE = 1; 
    //INTCONbits.PEIE = 1;
    //PIE1bits.ADIE = 1;
    //PIR1bits.ADIF = 0; 
    //PIR1bits.RCIF = 0; 
    //PIE1bits.RCIE = 1;
} 
void Envio_caracter(char caracter)
{
    while(!TXIF);       //Espera que envie dato TXIF = 1 siempre
    TXREG = caracter;   //Carga el caracter a TXREG y envía 
    return; 
}
void cadena_caracteres(char st[])
{
    int i = 0;          //i igual 0 posicion 
    while (st[i] !=0)   //revisar la posicion de valor de i 
    {
        Envio_caracter(st[i]); //enviar caracter de esa posicion 
        i++;                //incrementar variable para pasar a otra posicion 
    }                       //de cadena 
    return;
}
void Menuypreguntas(void)
{
    cadena_caracteres("\rSeleccione la opcion \r");
    cadena_caracteres("1 - Presentar cadena de caracteres\r");
    cadena_caracteres("2 - Mostrar en Puerto A\r");
    cadena_caracteres("3 - Mostrar en Puerto B\r");
}
