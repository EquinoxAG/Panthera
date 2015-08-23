%include"memory/virtual_memory.inc"

%define IA32_PAT_MSR 0x277

%define PAT_MEM_TYPE_UC 0
%define PAT_MEM_TYPE_WC 1
%define PAT_MEM_TYPE_WT 4
%define PAT_MEM_TYPE_WP 5
%define PAT_MEM_TYPE_WB 6
%define PAT_MEM_TYPE_UCWEAK 7



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
	test edx, (1<<20)	;Is nxe-bit supported?
	jz .no_nxe

	mov ecx, 0xC0000080	;Hardware enable the nxe bit
	rdmsr
	or eax, (1<<11)
	wrmsr
		
	xor eax, eax					;Create bitmask which with all bits set to ensure not resetting the nxe-bit
	not rax
	mov qword[ vm_driver.efer_nxe_bit ], rax	;The value in this field will be ored with the page table entry, if nxe is not supported nothing will change cause x or 0 = x

	.no_nxe:	
EndFunction

DeclareFunction MapVirtToPhys( virt_addr, phys_addr, size, flags )
	ReserveStackSpace PML4_Base, qword
	ReserveStackSpace PDPT_Base, qword
	ReserveStackSpace PDT_Base, qword
	UpdateStackPtr

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
	mov rdx, qword[ vm_driver.efer_nxe_bit ]

	;Resume from the above operations:
	;	r8 = Offset in the 4KB Page Tables
	; 	r9 = Offset in the 2MB Page Tables
	; 	r10 = Offset in the Page Directory Pointer Table
	;	r11 = Offset in the Page Map Lvl 4 Table
	;	r12 = flags
	; 	r13 = virt address
	;	r14 = phys address
	; 	r15 = size of the area
	; 	rdx = bitmask for the no executable bit

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


	.TotalRemap:
		mov rdi, cr3	;Load the current PML4 address	
		mov_ts qword[ PML4_Base ], rdi


	.ReenterPML4:
		mov_ts rdi, qword[ PML4_Base ]
		mov rax, r11	
		call Enter_CreateEnter_Dir
		mov_ts qword[ PDPT_Base ], rdi
	
	.ReenterPDPT:
		mov_ts rdi, qword[ PDPT_Base ]
		mov rax, r10
		call Enter_CreateEnter_Dir
		mov_ts qword[ PDT_Base ], rdi

	.StartMapping:
		mov_ts rdi, qword[ PDT_Base ]
		mov rcx, .Create4KBPage
		mov rax, .Create2MBPage
		

		test r8d, r8d
		cmovnz rax, rcx

		test r13d, 0xFFFFF
		cmovnz rax, rcx

		test r14d, 0xFFFFF
		cmovnz rax, rcx

		cmp r15, 0x200000
		cmovs rax, rcx

		jmp rax

	.Create4KBPage:
		mov rax, r9
		call Enter_CreateEnter_Dir	;Now rdi should point to the right Page Table
		add rdi, r8			;Calculate the right offset into the table
		mov eax, 0x1000

		.MapNext4KBPage:
			mov rsi, r14			;Get the right address into rsi
			call CreatePagePat

			add rdi, 8
			add r14, eax			;Increase address

			sub r15, eax
			jbe .done

			shr eax, 9

		.SelectNextEntry:
			add r8d, eax

			cmp r8d, 0x1000
			jnz .MapNext4KBPage

			xor r8d, r8d

			add r9d, 8

			cmp r9d, 0x1000
			jnz .StartMapping

			xor r9d, r9d

			add r10d, 8
			
			cmp r10d, 0x1000
			jnz .ReenterPDPT

			xor r10d, r10d

			add r11d, 8

			jmp .ReenterPML4

	.Create2MBPage:
		add rdi, r9		;Calculate the absolute offset off the page to create
		mov eax, 0x200000
		jmp .MapNext4KBPage


	.done:

EndFunction


	;rdi = addr of the entry, rsi = phys addr, r12 = flags of the page, rax = page size
	CreatePagePat:
		mov rbx, rax
		cmp eax, 0x200000			;If the page size is 2MB load the 2MB Mask in cx, else load the 4KB mask
		cmovnz cx, word[ vm_driver.4kb_mask ]
		cmovz cx, word[ vm_driver.2mb_mask ]

		or rsi, r12				;Load the right flags into rsi
		xor rax, rax
		and rsi, rdx				;And the current flags with the nxe-bit mask; NXE-Bitmask will flush the NXE-Bit if it is not supported by the hardware

		test si, (4<<3)				;Is the 3rd PAT Bit set?
		jz .write_page				;No write the page to memory

		xor si, cx				;Else flush the 3rd PAT-Bit and adjust it to the right position depending, on 2MB or 4KB page

	.write_page:
		lock cmpxchg qword[ rdi ], rsi		;Atomic write to the page table
		mov rax, rbx
		jnz Enter_CreateEnter_Dir.already_in_use
		ret




	Enter_CreateEnter_Dir:
		add rdi, rax
		
		mov rsi, qword[ rdi ]
		
		or rsi, rsi
		jz .create_new_dir

		test si, 1
		jz .already_in_use

		test si, (1<<7)
		jnz .already_in_use
		
		mov rdi, rsi
		and di, 0xF000
		ret

		.already_in_use:
			jmp $

		.create_new_dir:
			jmp $


fatal_no_pat:
	mov eax, 0x123412
	jmp $

vm_driver:
	.efer_nxe_bit dq 0x7FFFFFFFFFFFFFFF	
	.4kb_mask dw (1<<7)|(4<<3)
	.2mb_mask dw (1<<12)|(4<<3)
