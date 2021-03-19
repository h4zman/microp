nasm -f elf microp.asm  

ld -o "..\ELF Files"\microp.elf -T ..\link.x microp.o "..\ASM Library"\grove_rgb_lcd_lib.o "..\ASM Library"\cyp_io_expander.o "..\ASM Library"\galileo_gen_1.o 

pause

