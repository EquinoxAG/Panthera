%include "Morgenroetev1.inc"
%include "boot/multiboot.inc"
%include "heap/heap.inc"
%include "memory/virtual_memory.inc"
%include "vga/vga_driver.inc"
%include "string/string.inc"
%include "SD/system_desc.inc"
%include "exceptions/exception.inc"

;The main function takes one argument
global kernelMain
kernelMain:
	CreateStack kernelSt
	lidt [ZeroIdt]			;Load a zero idt until everything else is set up

	mov qword[MbrStrucAddr], rdi

	secure_call ClearScreen()

	;IMPORTANT InitialiseHeap must be executed before any other Initialisation function as the other intialisation function use malloc!!!!!!!!!!!!!!
	secure_call InitialiseHeap( BOOTUP_HEAP_ADDR, (BOOTUP_ID_MAP_SIZE-BOOTUP_HEAP_ADDR) )	;Initialise the bootup stack with the whole memory which was mapped

	;Next Initialise the system descriptors, means, initialise the gdt and the idt
	;Must be done before loading the exceptions or the apic
	secure_call InitialiseSD()
	
	;Now that the IDT is set up load the exceptions, will catch general exception faults, page faults, etc.
	secure_call InitialiseExceptions()


	;Initialise the virtual memory manager after the exceptions
	secure_call InitialiseVirtualMemoryManager( cr3 )


	mov dword[ 0xaffffff ], 0
	jmp $

ZeroIdt:
	.idt_limit dw 0
	.idt_base dq 0
section .bss
MbrStrucAddr resq 0


ImportAllMgrFunctions
