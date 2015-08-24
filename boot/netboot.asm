%include "Filesystem/elf64.inc"
%include "boot/multiboot.inc"
%include "pxe/pxe.inc"

%define mmap_addr 0x2004
%define FILEADDR 0xA00000


org 0x7C00
[BITS 16]
main:
	xor ax, ax
	mov ds, ax

	mov word[ PXEENVStruc ], es
	mov word[ PXEENVStruc + 2 ], bx
	
	mov cx, word[ es:bx + pxe_v1.RMEntry ]
	mov dx, word[ es:bx + pxe_v1.RMEntry+2 ]


	cmp word[ es:bx ], 0x201
	js .no_replace

	add sp, 4
	pop bx
	pop es


	mov word[ PXEENVStruc ], es
	mov word[ PXEENVStruc + 2 ], bx

	mov cx, word[ es:bx + pxe_v2.RMEntry ]
	mov dx, word[ es:bx + pxe_v2.RMEntry+2]

	.no_replace:

	mov word[ PXECall ], cx
	mov word[ PXECall+2 ], dx

	mov di, BUFPXENV_GET_CACHED
	mov bx, 0x0071

	call UsePXEAPI

	mov ax, 0xb800
	mov es, ax

	xor di, di

	mov si, word[ BUFPXENV_GET_CACHED.BufferOff ]
	push ds
	mov ds, word[ BUFPXENV_GET_CACHED.BufferSeg ]

	add si, 20
	
	;Load Server IP address
	mov eax, dword[ si ]
	;Load User agent IP addr
	mov ebx, dword[ si+4 ]

	pop ds

	mov word[ 0x500 + tft_open.Status ], 0
	mov dword[ 0x500 + tft_open.ServerIP ], eax
	mov dword[ 0x500 + tft_open.AgentIP ], ebx
	mov dword[ 0x500 + tft_open.Filename ], 'kern'
	mov dword[ 0x500 + tft_open.Filename+4 ], 'el.b'
	mov dword[ 0x500 + tft_open.Filename+8 ], 'in'
	mov word[ 0x500 + tft_open.port ], 69
	mov word[ 0x500 + tft_open.portcl ], 69
	mov dword[ 0x500 + tft_open.BufferSize ], 0xA00000
	mov dword[ 0x500 + tft_open.BufferAddr ], FILEADDR
	mov dword[ 0x500 + tft_open.MCastIP ], 0
	mov dword[ 0x500 + tft_open.timeout ], 0

	mov bx, 0x23
	mov di, 0x500
	call UsePXEAPI

	test ax, ax
	jz .good

	.fatal_error:
		jmp $

	.good:
	xor ax, ax
	mov es, ax
	mov ds, ax

	mov dword[ MultibootStrucAddr + multiboot.flags ], 64
	mov dword[ MultibootStrucAddr + multiboot.mmap_addr ], mmap_addr

	mov eax, 0xE820
	mov edx, 0x534D4150 
	xor ebx, ebx
	mov ecx, 24
	mov di, mmap_addr+4
	clc
	int 0x15
	jc .fatal_error

	sub di, 4
	mov dword[ di ], ecx
	add di, 4

	.again_mmap:

		mov edx, 0xE820
		xchg eax, edx
		add di, cx
		add di, 4
		int 0x15
		pushf
		sub di, 4
		mov dword[ di ], ecx
		add di, 4
		popf
		jc .next

		or ebx, ebx
		jnz .again_mmap

	.next:
		sub di, 4
		sub di, mmap_addr
		mov word[ MultibootStrucAddr + multiboot.mmap_length ], di




	cli
	lgdt[gdt_limit_mbr]

	in al, 0x92
	cmp al, 0xFF
	jz .fatal_error

	or al, 2
	and al, ~1
	out 0x92, al

	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp 0x8:ProtectedMode


UsePXEAPI:
	push ds
	push di
	push bx

	call far [PXECall]

	add sp, 4
	pop ds
	ret


[BITS 32]
ProtectedMode:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x300000

	mov ebx, FILEADDR	;ELF Header Address
	cmp dword[ ebx ], ELFMAGIC
	jnz .no_elf

	mov dx, word[ ebx + elf64header.programmheader_num ]	
	add ebx, dword[ ebx + elf64header.programmheader_offset ]		
	

	.loadAll:
		mov esi, dword[ ebx + programmheader.offsetinfile ]
		mov ecx, dword[ ebx + programmheader.sizeofsegmentinfile ]
		add esi, FILEADDR
		mov edi, dword[ ebx + programmheader.paddr ]

		push ecx
		shr ecx, 2

		rep movsd

		pop ecx
		and ecx, 0x3
		rep movsb


		add ebx, HeaderSize
		sub dx, 1
		jnz .loadAll


	mov eax, dword[ FILEADDR + elf64header.entry_point ]	
	push eax
	mov ebx, MultibootStrucAddr
	ret

	.no_elf:
		
		jmp $

gdt_limit_mbr dw 24
gdt_end_mbr dd gdt
gdt:
	dd 0
	dd 0
	
	dd 0xFFFF
	dd 0x00CF9A00
	
	dd 0xFFFF
	dd 0x00CF9200

PXECall dd 0
PXEENVStruc dd 0

BUFPXENV_GET_CACHED:
	.Status dw 0
	.PacketType dw 2
	.BufferSize dw 0
	.BufferOff dw 0
	.BufferSeg dw 0
	.BufferLimit dw 0

times 510 - ($-$$) hlt
dw 0xAA55

