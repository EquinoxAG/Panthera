%include "memory/virtual_memory.inc"

DeclareFunction InitialiseVirtualMemoryManager( bootup_pml4 )
	ReserveStackSpace OperatedPML4, qword
	UpdateStackPtr

	mov_ts qword[ OperatedPML4 ], Arg_bootup_pml4

	mov eax, 1
	cpuid
	test edx, (1<<16)
	jz fatal_no_pat

	mov eax, (PAT_MEM_TYPE_UC<<24)|(PAT_MEM_TYPE_UCWEAK<<16)|(PAT_MEM_TYPE_WT<<8)|(PAT_MEM_TYPE_WB)
	mov edx, (PAT_MEM_TYPE_WC<<24)|(PAT_MEM_TYPE_WP<<16)|(PAT_MEM_TYPE_WT<<8)|(PAT_MEM_TYPE_WB)
	mov ecx, IA32_PAT_MSR
	wrmsr				;Load the pat table!
					; Entry 0 : Cache type Write Back
					; Entry 1 : Cache type Write Through
					; Entry 2 : Cache type Uncachebale weak, can be overwritten by Write Combined
					; Entry 3 : Cache type Uncacheable
					; Entry 4 : Cache type Write back
					; Entry 5 : Cache type Write through
					; Entry 6 : Cache type Write protected
					; Entry 7 : Cache type Write Combined

	mov eax, 0x80000001	;Check if the Not executable bit is valid
	cpuid
	test edx, (1<<20)	;Is nxe bít supported?
	jz .no_nxe

	mov ecx, 0xC0000080	;It is supported hardware enable the nxe bit
	rdmsr
	or eax, (1<<11)
	wrmsr
		
	mov rax, 1		;Write the nxe bit in the 63-bit to disable executation in the area
	ror rax, 1		
	mov qword[ vm_driver.efer_nxe_bit ], rax	;The value in this field will be ored with the page table entry, if nxe is not supported nothing will change cause x or 0 = x

	.no_nxe:	
EndFunction

DeclareFunction MapVirtToPhys( virt_addr, phys_addr, size, flags )

	mov r8, Arg_virt_addr
	mov r9, Arg_virt_addr
	shr r8, 9
	mov r10, Arg_virt_addr
	shr r9, 18
	mov r11, Arg_virt_addr
	shr r10, 27
	and r8d, 0xFF8

	mov r12, Arg_flags
	shr r11, 36
	and r9d, 0xFF8
	mov r13, Arg_virt_addr
	and r10d, 0xFF8
	mov r14, Arg_phys_addr
	and r11d, 0xFF8
	mov r15, Arg_size

	;Resume from the above operations:
	;	r8 = Offset in the 4KB Page Tables
	; 	r9 = Offset in the 2MB Page Tables
	; 	r10 = Offset in the Page Directory Pointer Table
	;	r11 = Offset in the Page Map Lvl 4 Table
	;	r12 = flags
	; 	r13 = virt address
	;	r14 = phys address
	; 	r15 = size of the area
	
	xor eax, eax
	mov ecx, 0x1000

	test r13d, 0xFFF
	cmovnz eax, ecx
	test r14d, 0xFFF
	cmovnz eax, ecx

	and r13d, 0xFFFFF000
	and r14d, 0xFFFFF000
	add r15, rax 

	;Resume from the above operations:
	;	r13 = virt address aligned on 4KB
	;	r14 = phys address aligned on 4KB
	; 	r15 = size if virt address of phys address was not aligned on a 4KB boundary, the size will be increased by 4KB to ensure, that the whole memory is covered




	



EndFunction


fatal_no_pat:
	mov eax, 0x123412
	jmp $

vm_driver:
	.efer_nxe_bit dq 0
	.added_val dd 0x1000
