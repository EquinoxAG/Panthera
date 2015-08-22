%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)
%include "boot/multiboot.inc"

	section multiboot
	align 4
	my_magic dd MAGIC
	dd FLAGS
	dd CHECKSUM
	%define STACK_BASE_ADDR  0x5FFFF0
	%define GDT_BASE 0x900
	%define gdt_limit 0x980
	%define gdt_base 0x982
	extern kernel_start
	extern kernel_end


[BITS 32]
section .text
global _start
_start:
	mov esp, STACK_BASE_ADDR
	mov dword[ MultibootStruc_safer ], ebx

	mov eax, 0x80000001
	cpuid
	and edx, 0x20000000	;Check for the long mode support bit
	test edx, edx
	jz .fatal_error		;No long mode quit the OS
	mov eax, 1		;Check for the PAE-Bit ( Physical Address Extension)
	cpuid
	and edx, 0x40
	test edx, edx
	jz .fatal_error		;If not available quit OS

	xor eax, eax		;Set up new gdt to ensure transparence as well as enable 64 bit segment descriptors

	mov word[ gdt_limit ], 40
	mov dword[ gdt_base ], GDT_BASE
	mov dword[ GDT_BASE + 0 ], eax		; Null Descriptor
	mov dword[ GDT_BASE + 4 ], eax

	mov eax, 0xFFFF
	mov dword[ GDT_BASE + 8 ], eax		; Limit set to max for all 4 Descriptors
	mov dword[ GDT_BASE + 16 ], eax
	mov dword[ GDT_BASE + 24 ], eax
	mov dword[ GDT_BASE + 32 ], eax
	mov dword[ GDT_BASE + 40 ], eax
	mov dword[ GDT_BASE + 48 ], eax

	mov eax, 0x00CF9A00	
	mov dword[ GDT_BASE + 12 ], eax		;Code Segment 32-bit offset: 0x8

	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 20 ], eax		;Data Segment 32-Bit offset: 0x10

	mov eax, 0x00AF9A00
	mov dword[ GDT_BASE + 28 ], eax		;Code Segment 64-bit offset: 0x18
	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 36 ], eax		;Data Segment 64-bit offset: 0x20

	mov eax, 0x00F9A00
	mov dword[ GDT_BASE + 44 ], eax		;Code Segment 16-bit offset: 0x28
	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 52 ], eax		;Data Segment 16-bit offset: 0x30

	lgdt[ gdt_limit ]
	jmp 0x8:_OwnGDT	

	.fatal_error:	
		jmp $
			
		
align 8
	_OwnGDT:
		mov ax, 0x10	;Load new data descriptors
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax
	
		mov eax, cr4
		or eax, 0x20
		mov cr4, eax	; Set PAE-Bit 

		call InitialisePaging

		mov ecx, 0xC0000080
		rdmsr
		or eax, 0x100	;Set Long Mode Bit
		wrmsr

		mov eax, cr0	
		or eax, 0x80000000	;Activate Paging
		mov cr0, eax

		jmp 0x18:LongMode	; Enter long mode


InitialisePaging:
		mov edi, BOOTUP_PML4_ADDR	; Create the first paging structures at the BOOTUP_PML4_ADDR which is currently at 3MB
		xor eax, eax			; Clear all memory used to avoid possible unwanted pages
		mov ecx, 0x2000
		rep stosd

		mov edi, BOOTUP_PML4_ADDR


		mov eax, BOOTUP_PML4_ADDR + 0x100F
		xor ebx, ebx
	
		mov dword[ edi ], eax		; First PML4 entry maps 512GB by default
		mov dword[ edi + 4 ], ebx	; zero out upper half
		
		mov ecx, 1			; We need 4 entries to identity map all 4 GB memory
		add edi, 0x1000			; 0x601000
		push edi
		.MapAll:
			add eax, 0x1000
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add edi, 8

			sub ecx, 1
			jnz .MapAll

		pop edi
		add edi, 0x1000			;0x602000
		mov eax, 0x8B
		mov ecx, 5			; Map first 10 MB
			

		.Map:
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add edi, 8
			add eax, 0x200000
			adc ebx, 0
			sub ecx, 1
			jnz .Map

		mov eax, BOOTUP_PML4_ADDR
		mov cr3, eax
		ret				;Identity Mapped First GB


extern kernelMain

align 8
[BITS 64]
LongMode:
	mov ax, 0x20	;Load 64-bit Data descriptors
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax

	mov edi, dword[ MultibootStruc_safer ]
	call kernelMain

section .bss
MultibootStruc_safer resd 1
section .text
NoLongModeMsg db 'Long mode %x isi %d not available the OS can not boot please restart the PC', 0
