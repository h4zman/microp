;--------------------------------------------------------------------------
;File Name     		: microp.asm
;Version 			: taktau la version berapa dah
;Created Date		: 20/04/2019
;Last Update		: 21/05/2019
;Authors   			: - 
;Description		: Use pin IO_5 IO4 as a input to trigger a procedure that will 
;					  blink LEDs on pin IO_6 and motor on pin IO_7 
;
;Hardware 			: Grove-LED Socket, LEDs
;Macro files		: galileo_gen_1.mac, cyp_io_expander.mac
;Procedure files	: cyp_io_expander.o, galileo_gen_1.o
;--------------------------------------------------------------------------	
	
BITS 32						;tell the assembler-NASM that this is 32-bit 

%include "..\ASM Macro\galileo_gen_1.mac"			;included macro library
%include "..\ASM Macro\cyp_io_expander.mac"
%include "..\ASM Macro\grove_rgb_lcd.mac"		
%include "..\ASM Macro\grove_i2c_adc.mac"

;--------------------------------------------------------------------------
;External procedures
Extern delay, delay_1_53ms, delay_39us, delay_long, delay_short 
Extern lcd_initial, lcd_1st_line, lcd_2nd_line, 
Extern lcd_clear_screen, lcd_write_stop, lcd_data, lcd_print_data, lcd_write
Extern check 

;--------------------------------------------------------------------------data section
SECTION .data
msg_1		db 'Welcome Home'    ;message 1
msg_1_len 	equ	$-msg_1				;len has value, not an address
								;$ means current location		

msg_2		db 'Solat Subuh!! '	;message 2
msg_2_len 	equ	$-msg_2				;len has value, not an address

;--------------------------------------------------------------------------code section
SECTION .text						;CODE section

;--------------------------------------------------------------------------Step 1.Configuration
nop								;no operation	(please put two NOP as the 1st and 2nd instruction)
nop								;no operation	


call IO_5_set_input				;set IO_5 as Input switch
call IO_4_set_input				;set IO_4 as Input IR

call IO_6_set_output			;set IO_6 as Output LED
call IO_7_set_output			;set IO_7 as Output Fan

;--------------------------------------------------------------------------Step 1.Configuration lcd

enable_i2c													; invoke macro to enable i2c pin on the Galileo board
setup_soc_i2c_controller    IO_expander_ADDR				; 1. Configure slave device = IO Expande 
call lcd_initial											; 2. Initialize LCD controller

;--------------------------------------------------------------------------
;main program
;--------------------------------------------------------------------------
START: 
	
	read_cyp_io_input 		0x00		;invoke macro to read port_0 input data
							;port data will be moved to EDX register								
 	and edx, 0b0000_0010										;check IO_5 (port_0, bit_1)
	jnz turn_on_led				;jump to .turn_off_led if IO_5 (port_0, bit_1) is ZERO	
	
	read_cyp_io_input		0x01		;invoke macro to read port_0 input data
																				;port data will be moved to EDX register
	and edx, 0b0001_0000				;check IO_4 (port_1, bit_4)
	jz turn_on_ir			;jump to IO_4 (port_1, bit_3) is ZERO
	
offled:
	
	unset_cyp_io_pin   		Port_1_out,  0b1111_1110			;Switch OFF IO6	LED(port_1, bit_0)
	unset_cyp_io_pin     		Port_1_out,  0b1111_0111			;Switch OFF FAN (port_1, bit_3)
	JMP START

turn_on_ir:
	
	;unset_cyp_io_pin     Port_1_out,  0b1111_1110			  ;Switch OFF IO6 (port_1, bit_0)
	call lcd_on											; gerakkan wording lcd
	setup_soc_i2c_controller    IO_expander_ADDR		; 1. Configure slave device = IO Expande
	set_cyp_io_pin     	Port_1_out,  0b0000_0001
	set_cyp_io_pin     	Port_1_out,  0b0000_1000
	call delay_long
	
    JMP offled
	
turn_on_led:

	set_cyp_io_pin     	Port_1_out,  0b0000_0001				;Switch ON IO6 LED
	set_cyp_io_pin     	Port_1_out,  0b0000_1000			    ;Switch ON IO7 IR SENSOR (port_1, bit_3)	
	call delay_long
	JMP offled															;Jump back _start
;--------------------------------------------------------------------------
;procedures to setup Cypress CY8C9540A I/O expander
;--------------------------------------------------------------------------

;-----------------------------------------------set IO_5 as Input
IO_5_set_input:

push eax										
	
setup_soc_i2c_controller    IO_expander_ADDR		; 1. Configure slave device = IO Expander
	
cyp_io_expander_port_sel   	0x00						; 2. select Port 0
	
set_cyp_io_pin          	Port_0_pin_dir,	0b0000_0010		; 3. set pin direction to input - 0=output, 1=input  
																;    change GPORT0_BIT1 to 1

set_cyp_io_pin_drive_mode	Pull_Down,	   	0b0000_0010		; 4. set drive mode	to pull-down
												;    Grove switch is active high 
	
  pop eax

ret
;-----------------------------------------------

;-----------------------------------------------set IO_4 as Input
IO_4_set_input:

push eax										
	
setup_soc_i2c_controller    IO_expander_ADDR				; 1. Configure slave device = IO Expander
	
cyp_io_expander_port_sel   	0x01						; 2. select Port 0
	
set_cyp_io_pin          	Port_0_pin_dir,	0b0001_0000		; 3. set pin direction to input - 0=output, 1=input  
															;    change GPORT0_BIT1 to 1

set_cyp_io_pin_drive_mode	Pull_Down,	   0b0001_0000		; 4. set drive mode	to pull-down
												;    Grove switch is active high 
	
  pop eax

ret
;-----------------------------------------------

;-----------------------------------------------set IO_6 as Output
IO_6_set_output:

push eax										
	
setup_soc_i2c_co ntroller    IO_expander_ADDR			; 1. Configure slave device = IO Expander
	
cyp_io_expander_port_sel   	0x01							; 2. select Port 1
	
unset_cyp_io_pin          	Port_1_pin_dir,	0b1111_1110		; 3. set pin direction to output - 0=output, 1=input  	
																;    change GPORT1_BIT0 to 0
																
set_cyp_io_pin_drive_mode	Strong,	      	0b0000_0001		; 4. set drive mode to strong
	
  pop eax
	
ret
;-----------------------------------------------

;-----------------------------------------------set IO_7 as Output
IO_7_set_output:

push eax										
	
setup_soc_i2c_controller    IO_expander_ADDR				; 1. Configure slave device = IO Expander
	
cyp_io_expander_port_sel   	0x01							; 2. select Port 1
	
unset_cyp_io_pin          	Port_1_pin_dir,	0b1111_0111		; 3. set pin direction - 0=output, 1=input  	
																;    change GPORT1_BIT3 to 0	

set_cyp_io_pin_drive_mode	Strong,	      	0b0000_1000		; 4. set drive mode to strong	

pop eax

ret
;-----------------------------------------------


;----------------------------------------------------------------------------------------------- 	
lcd_on:

setup_soc_i2c_controller    IO_expander_ADDR				; 1. Configure slave device = IO Expander 
setup_soc_i2c_controller  RGB_ADDRESS	; Configure LCD as slave device
lcd_rgb_on cyan	        	   	 	; Switch on the LCD RGB LED and set to cyan color
setup_soc_i2c_controller   LCD_ADDRESS		; 1. Configure LCD as slave device #1 on i2c controller
											;    invoke macro, please refer to galileo_gen_1.mac										
	call lcd_initial							; 2. Initialize LCD controller
	call lcd_1st_line 							; Set cursor to head of 1st line
	call lcd_data								; Configure LCD to start display data
	mov esi, msg_1								; location of message 1
	mov ecx , msg_1_len							; number of bytes of the message
	call lcd_print_data							; print the string to LCD
	call lcd_2nd_line							; move LCD cursor to second line
	call lcd_data								; Set LCD to display data
	mov esi, msg_2								; location of message 2
	mov ecx , msg_2_len							; number of bytes of the message
	call lcd_print_data							; print the string to LCD
	
	call delay_long
	call lcd_clear_screen
	call lcd_write_stop
	
ret
;----------------------------------------------------------------------------------------------- 
