%include "SD/system_desc.inc"
%include "heap/heap.inc"

DeclareFunction InitialiseSD()
	cmp qword[ SystemDescriptors.idt_base ],  0
	jnz .done
	
	sgdt [SystemDescriptors.gdt_limit]

	secure_call malloc( 256*16, "Interrupt Descriptor Table", 0x1000 )
	mov dword[ SystemDescriptors.idt_base ], eax
	lidt [SystemDescriptors.idt_limit ]
	.done:
EndFunction


;Set a Interrupt gate with the specified interrupt number, the offset to the function to call and the desired
;descriptor privilegue level
DeclareFunction SetIDTGate( number, offset, dpl )
	cmp dword[ SystemDescriptors.idt_base ], 0
	jz .failed

	shl Arg_number, 4			;Multiply the number by 16 to get the offset into the idt
	add Arg_number, qword[ SystemDescriptors.idt_base ]	;Calculate the absolute address

	and Arg_dpl, 0x0F
	
	
	shl Arg_dpl, 13			;Move the descriptor privilegue level to the right offset
	
	xor eax, eax

	mov ax, si			;Load the low 16-bit offset
	or eax, (0x18<<16)			;Load the 64-bit code segment selector

	mov dword[ rdi ], eax		;Store the first 16-bit of the offset and the 64-bit selector in the descriptor

	mov eax, esi			;Load the low 32-bit of the offset
	and eax, 0xFFFF0000		;The low 16-bit of the offset has been written by now, therfore delete the low	16-bit
	shr rsi, 32			;Select the upper 32-bit of the offset
	or rax, Arg_dpl			;Add the descriptor priviluge level
	or eax, ((IDT_INTERRUPT_GATE64<<8)|(IDT_DESC_PRESENT<<8))	;The descriptor is present and an interrupt gate
	mov dword[ rdi + 4], eax	;Write the flags, the descriptor level and the bits 16-32 of the offset address
	mov dword[ rdi + 8], esi	;Write the high 32-bits of the 64-bit offset
	mov dword[ rdi + 12], 0		;Write 0 to the padding fields


	jmp .done
	
	.failed:

		stc			;Set the carry, because there is no idt to set a entry to
	.done:
EndFunction

MutexLock db 0
DeclareFunction CreateNewSegment( offset, dpl, gdt_type )
	mov rcx, Arg_offset
	mov r9, Arg_dpl
	and r9, 0x3
	mov r10, Arg_gdt_type
	and r10, 0xF

	mov al, 1

	.again:
		xchg byte[ MutexLock ], al
		test al, al
		jnz .again

	movzx edi, word[ SystemDescriptors.gdt_limit ]
	add edi, dword[ SystemDescriptors.gdt_base ]

	mov word[ edi ], 0xFFFF		;Limit max
	mov word[ edi + 2 ], cx
	shr rcx, 16
	mov byte[ edi + 4 ], cl
	shl r9, 5
	mov eax, GDT_PRESENT|0x10
	or eax, r9d
	or eax, r10d
	mov byte[ edi + 5 ], al

	mov al, 0xAF
	mov byte[ edi + 6 ], al
	shr rcx, 8
	mov byte[ edi + 7 ], cl

	movzx eax, word[ SystemDescriptors.gdt_limit ]
	add word[ SystemDescriptors.gdt_limit ], 8
	lgdt [SystemDescriptors.gdt_limit ]
	mov byte[ MutexLock ], 0
EndFunction




SystemDescriptors:
	.idt_limit dw 256*16
	.idt_base dq 0
	.gdt_limit dw 0
	.gdt_base dq 0

ImportAllMgrFunctions
