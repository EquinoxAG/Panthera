%include "Morgenroetev1.inc"
%include "boot/multiboot.inc"
%include "heap/heap.inc"
%include "memory/virtual_memory.inc"


;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt
	mov qword[MbrStrucAddr], rdi

	secure_call InitialiseHeap( 0xC00000, 0x200000 )

	secure_call InitialiseVirtualMemoryManager( cr3 )
	
	secure_call MapVirtToPhys( 0xC000000, 0x200000, 0x200000, PAGE_READ_WRITE|PAGE_CACHE_TYPE_WT ) 
	jmp $


section .bss
MbrStrucAddr resq 0

ImportAllMgrFunctions
