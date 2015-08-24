%include "Morgenroetev1.inc"
%include "boot/multiboot.inc"
%include "heap/heap.inc"
%include "memory/virtual_memory.inc"


;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt
	mov qword[MbrStrucAddr], rdi

	secure_call InitialiseHeap( BOOTUP_HEAP_ADDR, (BOOTUP_ID_MAP_SIZE-BOOTUP_HEAP_ADDR) )	;Initialise the bootup stack with the whole memory which was mapped

	secure_call InitialiseVirtualMemoryManager( cr3 )	;Initialise the virtual memory with the current cr3


	mov word[ 0xb8000 ], 0x0430
	jmp $

section .bss
MbrStrucAddr resq 0


ImportAllMgrFunctions
