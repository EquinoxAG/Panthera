%include"memory/virtual_memory.inc"
%include "heap/heap.inc"
%include "cpu/cpu.inc"
%include "vga/vga_driver.inc"

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

	mov rax, CPUInfoSignature
	cmp qword[ gs:CPUInfo.signature ], rax
	jnz fatal_no_pat

	.no_nxe:	
EndFunction

DeclareFunction MapVirtToPhys( virt_addr, phys_addr, size, flags )
	ReserveStackSpace PML4_Base, qword
	ReserveStackSpace PDPT_Base, qword
	ReserveStackSpace PDT_Base, qword
	ReserveStackSpace RBXBackup, qword
	ReserveStackSpace R14Backup, qword
	ReserveStackSpace R15Backup, qword
	UpdateStackPtr

	mov_ts qword[ RBXBackup ], rbx
	mov_ts qword[ R14Backup ], r14
	mov_ts qword[ R15Backup ], r15
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
	mov rdx, qword[ gs:CPUInfo.nxe_bit_mask ]

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

		test r13d, 0x1FFFFF
		cmovnz rax, rcx

		test r14d, 0x1FFFFF
		cmovnz rax, rcx

		cmp r15, 0x200000
		cmovs rax, rcx

		jmp rax

	.Create4KBPage:
		mov rax, r9
		call Enter_CreateEnter_Dir	;Now rdi should point to the right Page Table
	
		add rdi, r8			;Calculate the right offset into the table
		
		.MapNext4KBPage:
			mov eax, 0x1000

		.MapNextPage:
			push r12
			and r12d, ~PAGE_FORCE_OVERWRITE

			mov rsi, r14			;Get the right address into rsi
		
			;rdi = addr of the entry, rsi = phys addr, r12 = flags of the page, rax = page size
			mov rbx, rax
			cmp eax, 0x200000			;If the page size is 2MB load the 2MB Mask in cx, else load the 4KB mask
			cmovnz cx, word[ vm_driver.4kb_mask ]
			cmovz cx, word[ vm_driver.2mb_mask ]

			or rsi, r12				;Load the right flags into rsi
			xor rax, rax
			and rsi, rdx				;And the current flags with the nxe-bit mask; NXE-Bitmask will flush the NXE-Bit if it is not supported by the hardware

			pop r12
			test si, (4<<3)				;Is the 3rd PAT Bit set?
			jz .write_page				;No write the page to memory

			xor si, cx				;Else flush the 3rd PAT-Bit and adjust it to the right position depending, on 2MB or 4KB page


		.write_page:
			lock cmpxchg qword[ rdi ], rsi		;Atomic write to the page table	
			jz .continue

			test r12, PAGE_FORCE_OVERWRITE
			jz Enter_CreateEnter_Dir.already_in_use
			
			invlpg [r13]
	
		.force_write:
			lock cmpxchg qword[ rdi ], rsi
			jnz .force_write


		.continue:
			mov rax, rbx				;Restore the page size
			and r12w, ~PAGE_SIZE_FLAG		;Reset the page size bit, if the next page is 2MB again the function will set the bit again, but default is 4KB

			add rdi, 8				;Load address of the next entry
			add r14, rax				;Increase physical address by pagesize
			add r13, rax

			sub r15, rax				;Decrease size to map by pagesize
			jbe .done				;If everthing is mapped, jump to done

			shr eax, 9				;If eax holds the 2MB Page size = 0x200000>>9 = 0x1000; eax will therefore set r8d to the max value possible and init the turnover,
								;If eax holds the 4KB Page size = 0x1000>>9 = 8; eax will therefore select the next entry

		.SelectNextEntry:
			add r8d, eax				;Addd a specific value for the current page size, 2MB Pages will instantly toogle the overrun, while 4KB Pages will only increase r8d by 8

			cmp r8d, 0x1000				;If the end of the Page Table is reached, reset r8d and increase the index in the Page directory table
			jnz .MapNext4KBPage

			xor r8d, r8d			

			add r9d, 8				;Increase the index in the page direcory table

			cmp r9d, 0x1000				;If no ovrerrun occures, Jump again to start mapping and create a new directory if the page size 4KB is selected
			jnz .StartMapping

			xor r9d, r9d				;If r9d did overrun reset it and increase the index in the Page directory pointer table

			add r10d, 8				
			
			cmp r10d, 0x1000
			jnz .ReenterPDPT			;Create the new directory

			xor r10d, r10d

			add r11d, 8

			jmp .ReenterPML4

	.Create2MBPage:
		add rdi, r9			;Calculate the absolute offset off the page to create
		mov eax, 0x200000		;Page size is 2MB
		or r12d, PAGE_SIZE_FLAG		;Set the page size bit in order to set a page with the size of 2MB
		jmp .MapNextPage


	.done:
		xor eax, eax			;Everything wents well, so reset eax
		mov_ts rbx, qword[ RBXBackup ]
		mov_ts r14, qword[ R14Backup ]
		mov_ts r15, qword[ R15Backup ]
EndFunction







	Enter_CreateEnter_Dir:
		CreateStack DckStack
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
		
		jmp .end

		.already_in_use:
			test r12, PAGE_FORCE_OVERWRITE
			invlpg [r13]
			jnz .create_new_dir

			secure_call DrawString("Try overwrite dir")
			mov eax, 1
			jmp $

		.create_new_dir:
			push rcx
			push rdx
			push r8
			push r9
			push r10
			push r11
			push r12
			push r13
			push r14
			push r15
			
			mov rbx, rdi
			secure_call malloc( 0x1000, "Virtual memory page directory", 0x1000 )
			push rax
			
			mov rdi, rax
			mov ecx, 0x1000/8
			xor rax, rax
			rep stosq

			pop rdi

			mov rax, rdi
			or ax, 0x0F
			mov qword[ rbx ], rax
	
			pop r15
			pop r14
			pop r13
			pop r12
			pop r11
			pop r10
			pop r9
			pop r8
			pop rdx
			pop rcx
			
			.end:
			DestroyStack DckStack
			ret



fatal_no_pat:
	mov eax, 0x123412
	jmp $

vm_driver:
	.4kb_mask dw (1<<7)|(4<<3)
	.2mb_mask dw (1<<12)|(4<<3)

ImportAllMgrFunctions
