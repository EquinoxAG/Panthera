%include "SD/system_desc.inc"
%include "heap/heap.inc"

DeclareFunction InitialiseSD()
	;If the idt_base is non zero the System Descriptors have already been initialised
	cmp qword[ SystemDescriptors.idt_base ],  0
	jnz .done

	;Load the propertys of the global descriptor table in the buffer
	sgdt [SystemDescriptors.gdt_limit]

	;Reserve enough space for the interrupt descriptor table on a 4KB boundary
	secure_call malloc( 256*16, "Interrupt Descriptor Table", 0x1000 )
	;Save the new idt base
	mov dword[ SystemDescriptors.idt_base ], eax

	
	.done:	
		;Load the new idt, even if the idt has been loaded already, it won't harm the cpu if it is loaded again
		lidt [SystemDescriptors.idt_limit]
EndFunction


;Set a Interrupt gate with the specified interrupt number, the offset to the function to call and the desired
;descriptor privilegue level
DeclareFunction SetIDTGate( number, offset, dpl )

	;If there is no idt loaded by now, the setIDTGate function can not set a gate, therefore quit the function with an error code
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

MutexLock db 0	;The mutex locks the create new segment function, as a new segment must be initialised by only one cpu at a time

DeclareFunction CreateNewSegment( offset, dpl, gdt_type )
	mov rcx, Arg_offset
	mov r9, Arg_dpl
	and r9, 0x3
	mov r10, Arg_gdt_type
	and r10, 0xF

	;Lock the mutex
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

	;Unlock the mutex
	mov byte[ MutexLock ], 0
EndFunction


;Stack layout must be before call 
; [rsp] = address to store to
; [rsp + 8] = rip
; [rsp + 16 ] = cs
; [rsp + 24 ] = rflags
; [rsp + 32 ] = rsp
; [rsp + 40 ] = ss
DeclareFunction DumpRegisters()
	push rbx
	push rax
	
	mov rax, qword[ rbp + 16 ]
	
	mov qword[ rax + CPURegisters.rbx ], rbx
	mov qword[ rax + CPURegisters.rcx ], rcx
	mov qword[ rax + CPURegisters.rdx ], rdx
	mov qword[ rax + CPURegisters.rsi ], rsi
	mov qword[ rax + CPURegisters.rdi ], rdi
	mov qword[ rax + CPURegisters.r8 ], r8
	mov qword[ rax + CPURegisters.r9 ], r9
	mov qword[ rax + CPURegisters.r10 ], r10
	mov qword[ rax + CPURegisters.r11 ], r11
	mov qword[ rax + CPURegisters.r12 ], r12
	mov qword[ rax + CPURegisters.r13 ], r13
	mov qword[ rax + CPURegisters.r14 ], r14
	mov qword[ rax + CPURegisters.r15 ], r15
	mov rbx, qword[ rbp + 24 ];rip
	mov qword[ rax + CPURegisters.rip ], rbx
	mov rbx, qword[ rbp + 32 ];cs
	mov qword[ rax + CPURegisters.cs ], rbx
	mov rbx, qword[ rbp + 40 ];rflags
	mov qword[ rax + CPURegisters.rflags ], rbx
	mov rbx, qword[ rbp + 48 ];rsp
	mov qword[ rax + CPURegisters.rsp ], rbx
	mov rbx, qword[ rbp + 56 ]
	mov qword[ rax + CPURegisters.ss ], rbx
	mov ebx, ds
	mov qword[ rax + CPURegisters.ds ], rbx
	mov ebx, es
	mov qword[ rax + CPURegisters.es ], rbx
	mov ebx, fs
	mov qword[ rax + CPURegisters.fs ], rbx
	mov ebx, gs
	mov qword[ rax + CPURegisters.gs ], rbx
	pop rbx
	mov qword[ rax + CPURegisters.rax ], rbx
	mov rax, rbx
	pop rbx
EndFunction




SystemDescriptors:
	.idt_limit dw 256*16
	.idt_base dq 0
	.gdt_limit dw 0
	.gdt_base dq 0

ImportAllMgrFunctions
