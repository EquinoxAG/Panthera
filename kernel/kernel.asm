%include "Morgenroetev1.inc"
%include "boot/multiboot.inc"
%include "heap/heap.inc"
%include "memory/virtual_memory.inc"
%include "vga/vga_driver.inc"
%include "string/string.inc"

;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt
	mov qword[MbrStrucAddr], rdi
	secure_call InitialiseHeap( BOOTUP_HEAP_ADDR, (BOOTUP_ID_MAP_SIZE-BOOTUP_HEAP_ADDR) )	;Initialise the bootup stack with the whole memory which was mapped

	secure_call InitialiseVirtualMemoryManager( cr3 )	;Initialise the virtual memory with the current cr3

	secure_call MapVirtToPhys( 0xFEE00000, 0xFEE00000, 0x1000, PAGE_CACHE_TYPE_UC|PAGE_READ_WRITE)
	secure_call ClearScreen()

	.loop:
		mov ebx, 0
	.DrawDelay:
		add ebx, 1
		cmp ebx, 0xFFFFFFF
		jnz .DrawDelay
		secure_call PrintMemoryMap()
		jmp .loop
	jmp $

section .bss
MbrStrucAddr resq 0


ImportAllMgrFunctions
