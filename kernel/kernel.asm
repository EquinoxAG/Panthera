%include "Morgenroetev1.inc"
INCLUDE "boot/multiboot.inc"

;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt

	mov qword[MbrStrucAddr], rdi
	jmp $


section .bss
MbrStrucAddr resq 0

ImportAllMgrFunctions
