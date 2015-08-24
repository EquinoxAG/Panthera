%include "Morgenroetev1.inc"
INCLUDE "heap/heap.inc"
INCLUDE "vga/vga_driver.inc"
INCLUDE "string/string.inc"


;Initalises the Heap with the specified size
DeclareFunction InitialiseHeap( address, size )
	mov dword[ HeapSettings.PhysicalAddr ], edi
	mov ebx, esi
	mov eax, edi

	;Now after the size has been aligned save the real size of the heap
	mov dword[ HeapSettings.size ], esi

	;rax = holds the base address of the heap
	mov dword[ HeapSettings.PhysicalAddr ], eax
	
	;Calculate in edi the end address of the heap
	mov edi, eax
	;Initialise the first and only Memory Block Header
	mov dword[ eax + HeapInfoBlock.next ], 0

	;edi = max address of the heap
	add edi, ebx

	;ebx = size of the heap allocatable memory
	sub ebx, (HeapInfoBlock_size)

	;Initialise the only memory block header 
	mov dword[ eax + HeapInfoBlock.size ], ebx
	mov dword[ eax + HeapInfoBlock.alloc_reason ], BLOCK_FREE

	;Save the max address of the heap
	mov dword[ HeapSettings.PhysicalAddrEnd ], edi

	;Save the first entry address!
	mov dword[ HeapSettings.first_entry ], eax
EndFunction


DeclareFunction malloc( size, string_addr, alignment )
	mov r12, rbx
	
	xor r15d, r15d
	mov eax, 1
	.BuildMask:
		test Arg_alignment, rax
		jnz .BuildMask_end

		or r15d, eax
		shl eax, 1
		jmp .BuildMask

	.BuildMask_end:
		not r15

	mov r8, Arg_string_addr
	mov r9, Arg_size

	mov edi, dword[ HeapSettings.first_entry ]

	add r9d, HeapInfoBlock_size
	mov r10d, r9d
	.StartTraverse:
		mov r9d, r10d
		mov eax, dword[ edi + HeapInfoBlock.size ]
		mov ebx, edi
		add ebx, eax	;ebx = end address of the memory
		add ebx, HeapInfoBlock_size
		mov ecx, ebx
		sub ecx, r9d	;ecx = start address of the info block
		and rcx, r15	;ecx = aligned start address of the info block
		sub ecx, HeapInfoBlock_size;ecx = aligned start address of the memory block
		sub ebx, ecx	; ebx = aligned size


		mov r9d, ebx



		cmp eax, r9d
		jns .lock_block

	.SelectNextBlock:
		mov edi, dword[ edi + HeapInfoBlock.next ]
		test edi, edi
		jnz .StartTraverse

		jmp $

	.lock_block:
		mov ebx, eax
		;edx:eax = comparator value
		xor edx, edx
		;ecx:ebx = new value
		xor ecx, ecx
		sub ebx, r9d	;ebx = new size value

	.try_to_lock:
		lock cmpxchg8b [ edi + HeapInfoBlock.size ]
		jz .createTheBlock

		;okay comparision did fail. If the allocation_reason if above 256 it is a permanently locked block
		;Else try the next lock

		cmp ecx, 256	;Permanently locked block maybe because of merging or things like that
		mov eax, ebx
		jae .SelectNextBlock

		;If the block is still big enough try again
		cmp ebx, r9d
		jns .lock_block
		jmp .SelectNextBlock

	.createTheBlock:
		mov eax, edi
		sub r9d, HeapInfoBlock_size
		add edi, ebx

		mov esi, DefaultMemUsage
		add edi, HeapInfoBlock_size
		test r8d, r8d
		mov dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_UPDATE
		cmovz r8d, esi
		mov ecx, ebx
		mov dword[ edi + HeapInfoBlockReserved.size ], r9d
		mov dword[ edi + HeapInfoBlockReserved.last_ptr ], eax
		mov r11d, edi
		mov dword[ edi + HeapInfoBlockReserved.alloc_reason ], r8d

		add edi, r9d
		add edi, HeapInfoBlock_size
		;edi = next block in line
		cmp edi, dword[ HeapSettings.PhysicalAddrEnd ]
		jz .done

		cmp dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_RESERVED
		js .done

		mov dword[ edi + HeapInfoBlockReserved.last_ptr ], r11d
		
	.done:
		mov eax, r11d
		add eax, HeapInfoBlockReserved_size
		mov rbx, r12

EndFunction


DeclareFunction malloc( size, string_addr )
	mov r12, rbx
	mov r8, Arg_string_addr
	mov r9, Arg_size

	mov edi, dword[ HeapSettings.first_entry ]

	add r9d, HeapInfoBlock_size
	.StartTraverse:
		mov eax, dword[ edi + HeapInfoBlock.size ]

		cmp eax, r9d
		jns .lock_block

	.SelectNextBlock:
		mov edi, dword[ edi + HeapInfoBlock.next ]
		test edi, edi
		jnz .StartTraverse

		jmp $

	.lock_block:
		mov ebx, eax
		;edx:eax = comparator value
		xor edx, edx
		;ecx:ebx = new value
		xor ecx, ecx
		sub ebx, r9d	;ebx = new size value

	.try_to_lock:
		lock cmpxchg8b [ edi + HeapInfoBlock.size ]
		jz .createTheBlock

		;okay comparision did fail. If the allocation_reason if above 256 it is a permanently locked block
		;Else try the next lock

		cmp ecx, 256	;Permanently locked block maybe because of merging or things like that
		mov eax, ebx
		jae .SelectNextBlock

		;If the block is still big enough try again
		cmp ebx, r9d
		jns .lock_block
		jmp .SelectNextBlock

	.createTheBlock:
		mov eax, edi
		sub r9d, HeapInfoBlock_size
		add edi, ebx

		mov esi, DefaultMemUsage
		add edi, HeapInfoBlock_size
		test r8d, r8d
		mov dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_UPDATE
		cmovz r8d, esi
		mov ecx, ebx
		mov dword[ edi + HeapInfoBlockReserved.size ], r9d
		mov dword[ edi + HeapInfoBlockReserved.last_ptr ], eax
		mov r11d, edi
		mov dword[ edi + HeapInfoBlockReserved.alloc_reason ], r8d

		add edi, r9d
		add edi, HeapInfoBlock_size
		;edi = next block in line
		cmp edi, dword[ HeapSettings.PhysicalAddrEnd ]
		jz .done

		cmp dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_RESERVED
		js .done

		mov dword[ edi + HeapInfoBlockReserved.last_ptr ], r11d
		
	.done:
		mov eax, r11d
		add eax, HeapInfoBlockReserved_size
		mov rbx, r12
EndFunction


;DeclareFunction PrintFreeMap()
;	mov ebx, dword[ HeapSettings.first_entry ]
;	ReserveStackSpace HeaderStr, KString1024
;	UpdateStackPtr

;	secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_YELLOW),0x0A,"Printing Heap free memory map",0x0A})
;
;	.StartTraverse:
;		secure_call HeaderStr.append_str({ CONSOLE_CHANGEFG(COLOR_YELLOW),"Base addr: ", CONSOLE_CHANGEFG(COLOR_MAGENTA)})
;		mov eax, ebx
;		add eax, HeapInfoBlock_size
;		secure_call HeaderStr.append_inth( rax )
;		secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_YELLOW)," | Length: ", CONSOLE_CHANGEFG(COLOR_MAGENTA)})
;		mov eax, dword[ ebx + HeapInfoBlock.size ]
;		secure_call HeaderStr.append_inth( rax )
;		secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_YELLOW), " | a_r: ", CONSOLE_CHANGEFG(COLOR_MAGENTA)})
;		mov eax, dword[ ebx + HeapInfoBlock.alloc_reason ]
;		secure_call HeaderStr.append_inth( rax )
;
;		secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE),0x0A})
;		mov ebx, dword[ ebx + HeapInfoBlock.next ]
;		test ebx, ebx
;		jnz .StartTraverse
;
;		secure_call HeaderStr.c_str()
;		secure_call DrawString( rax )
;EndFunction

DeclareFunction PrintMemoryMap()
	mov ebx, dword[ HeapSettings.PhysicalAddr ]

	ReserveStackSpace HeaderStr, KString1024
	UpdateStackPtr

	secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE),0x0A,"Printing Heap complete memory map",0x0A})

	.StartTraverse:
		secure_call HeaderStr.append_str({"Base addr: ", CONSOLE_CHANGEFG(COLOR_BROWN)})
		mov eax, ebx
		add eax, HeapInfoBlock_size
		secure_call HeaderStr.append_inth( rax )
		secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE)," | Length: ", CONSOLE_CHANGEFG(COLOR_BROWN)})
		mov eax, dword[ ebx + HeapInfoBlock.size ]
		secure_call HeaderStr.append_inth( rax )

		secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE), " | Usage: ", CONSOLE_CHANGEFG(COLOR_BROWN)})

		mov eax, dword[ ebx + HeapInfoBlock.alloc_reason ]

		cmp eax, BLOCK_USERDEFINED
		ja .userdef

		secure_call HeaderStr.append_str( "Free memory" )
		jmp .next

		.userdef:
			secure_call HeaderStr.append_str( rax )

		.next:
			secure_call HeaderStr.append_str({CONSOLE_CHANGEFG(COLOR_WHITE),0x0A})
			add ebx, dword[ ebx + HeapInfoBlock.size ]
			add ebx, HeapInfoBlock_size
			cmp ebx, dword[ HeapSettings.PhysicalAddrEnd ]
			jnz .StartTraverse

		secure_call HeaderStr.c_str()
		secure_call DrawString( rax )
EndFunction


;esi = addr, ebx = value to write
LockThing:
	xor eax, eax
	
.no_eax:
	mov edx, ebx
	lock cmpxchg dword[ esi + HeapInfoBlockReserved.alloc_reason ], edx
	jz .done
	
	cmp edx, BLOCK_RESERVED
	js .no_eax

	stc
	ret
	.done:
		clc
		ret

align 8
UpdateLockerFree dq 0
;edi = free addr
DeclareFunction free(address)
	mov r12, rbx
	sub edi, HeapInfoBlock_size


	cmp dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_USERDEFINED
	js .done


	mov eax, edi
	mov dword[ edi + HeapInfoBlockReserved.alloc_reason ], BLOCK_ON_MERGE
	mov esi, dword[ edi + HeapInfoBlockReserved.last_ptr ]
	mov r8d, dword[ edi + HeapInfoBlockReserved.size ]
	sub eax, esi


	;edx:eax = comparator value
	xor edx, edx


	;ecx:ebx = new val
	mov ebx, eax
	mov ecx, BLOCK_ON_MERGE
	sub eax, HeapInfoBlock_size
	add ebx, r8d
	xor r9d, r9d

	.NextLockLow:
		lock cmpxchg8b [esi+HeapInfoBlockReserved.size ]
		jz .unty_lower

		test ecx, ecx
		jnz .merge_upper

		mov esi, dword[ edi + HeapInfoBlockReserved.last_ptr ]
		mov ebx, r8d
		mov ecx, BLOCK_ON_MERGE
		sub eax, esi
		add ebx, eax
		sub eax, HeapInfoBlock_size
		jmp .NextLockLow

	.unty_lower:
		mov r9d, 1	;No need to unty lower, next and last will be used to bring the block in the list
		mov edi, esi
	.merge_upper:
		mov esi, edi
		add esi, dword[ edi + HeapInfoBlockReserved.size ]
		add esi, HeapInfoBlockReserved_size			;esi = address of next block
		
		cmp esi, dword[ HeapSettings.PhysicalAddrEnd ]
		jz .bring_online

		.try_lock_again:
			;Block must be free
			mov ebx, BLOCK_ON_MERGE_DESTRUCTIVE
			call LockThing
			jnc .unty_upper		;Lock succeed

			mov dword[ esi + HeapInfoBlockReserved.last_ptr ], esi
			jmp .bring_online
		.unty_upper:
			mov eax, dword[ esi + HeapInfoBlockReserved.size ]
			add eax, HeapInfoBlock_size
			mov ebx, esi
			add dword[ edi + HeapInfoBlock.size ], eax

			
			mov esi, HeapSettings.PhysicalAddrEnd
			
			.TryLock:
				mov al, 1
				xchg byte[ UpdateLockerFree ], al
				test al, al
				jnz .TryLock

			.LoopedUnty:
				cmp dword[ esi + HeapInfoBlock.next ], ebx
				jz .EndUnty
				
				mov esi, dword[ esi + HeapInfoBlock.next ]
				jmp .LoopedUnty


			.EndUnty:
				mov eax, dword[ ebx + HeapInfoBlock.next ]
				mov dword[ esi + HeapInfoBlock.next ], eax
				mov byte[ UpdateLockerFree ], 0
				
			
	.bring_online:
		test r9d, r9d
		jnz .almost_done

		mov esi, edi
	.again:
		mov eax, dword[ HeapSettings.first_entry ]
		mov dword[ edi + HeapInfoBlock.next ], eax
		lock cmpxchg dword[ HeapSettings.first_entry ], edi
		jz .almost_done
		mov edi, esi
		jmp .again

	.almost_done:
		mov dword[ edi + HeapInfoBlock.alloc_reason ], BLOCK_FREE
	.done:
		mov rbx, r12
EndFunction


DefaultMemUsage db 'Reserved memory',0
ImportAllMgrFunctions
section .bss
HeapSettings:
	.PhysicalAddr resd 1
	.PhysicalAddrEnd resd 1
	.size resd 1
	.first_entry resd 1

