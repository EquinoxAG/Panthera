%include "exceptions/exception.inc"
%include "vga/vga_driver.inc"
%include "heap/heap.inc"
%include "string/string.inc"
%include "SD/system_desc.inc"

; Sets an breakpoint at the specified address triggers if the specified condition is met
; * break_addr = rdi = address at which the cpu will invoke the breakpoint exception
; * call_addr = rsi = function will get called at breakpoint exception
; * type = instruction triggered, write triggered, write_read triggered, io triggered
; * mem_size = range at which exception will trigger, for instructions always 0
DeclareFunction SetDebugBreakpoint( break_addr, call_addr, type, mem_size )
	;If no handler is installed by now, install it first
	cmp dword[ exception_settings.dbg_excp_handler ], 0
	jz .initialiseFirst

	; Now that the handler is set load the information about the breakpoints into eax
	.handlerSet:	
		and Arg_mem_size, 3	;The memory range field is only defined for the values 0-3
		and Arg_type, 3		;The type field is only defined for the values 0-3 therefore limitate it to that value

		xor ecx, ecx	;First, the debug register dr0 will be checked if it is in use, if not it will be used to hold the current breakpoint request
		
		
		cmp Arg_type, EXCP_BREAKPOINT_INST
		cmovz edx, ecx			;If the breakpoint triggers on instructions the mem range field is hardwired to 0, therefore set the mem range to zero

		mov r8, Arg_type
		mov rdx, Arg_mem_size	
		shl r8w, 8
		shl dx, 10		;Shift the memory range bits to the right place

		

		mov rax, dr7
		
		or dx, EXCP_GLOBAL_BREAKPOINT		;The breakpoint is by default global
		or dx, r8w				;Load the trigger operation into the flags register
	
	.selectSlot:
		push .end	;The function to which will be jumped in a few lines returns at the end, therefore provide a return address
	
		;dr7 layout:
		;8					0  Bits
		;-----------------------------------------
		;| G3 | L3 | G2 | L2 | G1 | L1 | G0 | L0 |
		;-----------------------------------------

		;16				    8 Bits
		;------------------------------------
		;| 0 | 0 | GD | 0 | 0 | 1 | LE | GE |
		;------------------------------------



		;Is the first debug register set free?
		test eax, 3	
		jz SetDebugRegisterSlot.slot_0

		;Is the second debug register set free?
		add ecx, 1		;Select second register set
		test eax, 0xA
		jz SetDebugRegisterSlot.slot_1

		;Is the third debug register free?
		add ecx, 1		;Select third register set
		test eax, 0x30
		jz SetDebugRegisterSlot.slot_2

		;Is the fourth debug register set free?
		add ecx, 1		;Select fourth register ste
		test eax, 0xA0
		jz SetDebugRegisterSlot.slot_3

		pop r8		;No function has been called, therefore the return address is still on the stack

		xor eax, eax		; eax is zero if the function failes
		stc			;Set the carry flag because no free debug register could be found
		jmp .end

	;No handler is installed therefore install the handler
	.initialiseFirst:
		secure_call InitialiseExceptions()
		;Continue with the allocation of the breakpoint
		jmp .handlerSet
	.end:
EndFunction


;Unset a breakpoint by the handle returned on setting the breakpoint
DeclareFunction UnsetBreakpoint( handle )
	cmp Arg_handle, 0xFFFFF00	;valid handles are all above 0xFFFFFF00
	js .end

	mov rax, dr7	;Load the information about the currently in use breakpoints
	and eax, edi	;The handle is a mask which will zero out the right debug register set
	mov dr7, rax	;Load the changed register sets back to the debug register

	.end:
EndFunction


DivideByZeroException:
	cli
	secure_call DrawString("Divide by zero exception")
	jmp $

NonMaskableInterrupt:
	cli
	secure_call DrawString("Non Maskable interrupt occured")
	jmp $

BreakpointException:
	cli
	secure_call DrawString("Breakpoint exception")
	jmp $
	
OverflowException:
	cli
	secure_call DrawString("Overflow exception")
	jmp $
BoundRangeExceedException:
	cli
	secure_call DrawString("Bound Range exceed exception")
	jmp $

InvalidOpcodeException:
	cli
	secure_call DrawString("Invalid opcode exception")
	jmp $
DeviceNotAvailableException:
	cli
	secure_call DrawString("Device not available exception")
	jmp $
DoubleFaultException:
	cli
	secure_call DrawString("Double Fault exception")
	jmp $

CoprocessorSegmentOverrun:
	cli
	secure_call DrawString("Coprocessor segment overrun")
	jmp $

InvalidTSSException:
	cli
	secure_call DrawString("Invalid TSS Exception")
	jmp $

SegmentNotPresent:
	cli
	secure_call DrawString("Segment not present")
	jmp $
StackFaultException:
	cli
	secure_call DrawString("Stack fault exception")
	jmp $
GeneralProtectionFault:
	cli
	secure_call DrawString("General Protection Fault")
	jmp $

PageFaultException:
	cli
	secure_call DrawString("Page fault exception")
	jmp $

DeclareFunction InitialiseExceptions()
	;This function must not change any values, therefore save the register which may be trashed
	push rdi
	push rsi
	push rdx
	push rcx

	secure_call SetIDTGate( 0, DivideByZeroException, 3 )
	secure_call SetIDTGate( 2, NonMaskableInterrupt, 3 )
	secure_call SetIDTGate( 3, BreakpointException, 3 )
	secure_call SetIDTGate( 4, OverflowException, 3 )
	secure_call SetIDTGate( 5, BoundRangeExceedException, 3 )
	secure_call SetIDTGate( 6, InvalidOpcodeException, 3 )
	secure_call SetIDTGate( 7, DeviceNotAvailableException, 3 )
	secure_call SetIDTGate( 8, DoubleFaultException, 3 )
	secure_call SetIDTGate( 9, CoprocessorSegmentOverrun, 3 )
	secure_call SetIDTGate( 10, InvalidTSSException, 3 )
	secure_call SetIDTGate( 11, SegmentNotPresent, 3 )
	secure_call SetIDTGate( 12, StackFaultException, 3 )
	secure_call SetIDTGate( 13, GeneralProtectionFault, 3 )
	secure_call SetIDTGate( 14, PageFaultException, 3 )

	;Set the IDT Entry for the Interrupt 1 which is the #1 Debug Exception Interrupt, it should be callable from usermode
	secure_call SetIDTGate( 1, DebugException, 3 )
	jc .fatal_error

	;Load the current debug exception handler into the settings, so that the module knowns about the installed handler
	mov qword[ exception_settings.dbg_excp_handler ], DebugException


	;Restore the trashed registers and continue the execution
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	jmp .end

	.fatal_error:
		;If the gate could not be set, print the error on the screen and halt the processor
		secure_call ClearScreen()
		secure_call DrawString( {CONSOLE_CHANGEFG(COLOR_BRIGHTRED), "Could not set up the exceptions, because the IDT is not set up by now!"})
		jmp $
	.end:
EndFunction

;Sets the specifed slot with the needed attributes
;* edi = address of the breakpoint
;* rsi = address to call if breakpoint triggers
;* dl = visibility flags;  1 = local visible( deleted through task change ), 2 = global visible, 3 = global & local
;* dh = flags, low two bits: 0 = instruction breakpoint, 1 = Write to the address, 2 = IO at that address, 3 = read or write to that address
;	high two bits = length of the watched memory area: 0 = 1 Byte or for instruction breakpoints, 1 = 2 Byte length, 2 = 8 Bytes length, 3 = 4 Bytes length
; ecx = register slot
SetDebugRegisterSlot:
	.slot_0:
		mov dr0, rdi			;Load the address which needs to be debugged into the right debug register 
		mov r8d, 0xFFFFFFFC		;Set up the handle for later
		jmp .start_map
	.slot_1:
		mov dr1, rdi			; see above
		mov r8d, 0xFFFFFFF3
		jmp .start_map
	.slot_2:
		mov dr2, rdi			; see above
		mov r8d, 0xFFFFFFCF
		jmp .start_map
	.slot_3:
		mov dr3, rdi			; see above
		mov r8d, 0xFFFFFF3F

	.start_map:
		mov qword[ ecx*8 + exception_settings.debug_0_handler ], rsi	;Store the function address which will be invoked on breakpoint trigger
		mov byte[ ecx + exception_settings.debug_0_type ], dh		;Store the breakpoint trigger type	

		shl cl, 1		;Multiply the index of the debug register by two because the visibility flag field is two bits wide
		mov rax, dr7	

		shl dl, cl	;Shift the visibility flags to the right position
		
		or al, dl	;Write the visibility flags	
	
		add cl, cl	;Double the index again to prepare cl to shift breakpoint type to the right bit positions
		mov edi, dword[ exception_settings.mask_0 + ecx ]		;Load the right mask into edi
		add cl, 8	;Add 8 to cl because the first 8 bits must be skipped, then on there are 4-bit wide fields per debug register set

		xor dl, dl	; The visibility flags has been written by now, zero them to not trash anything
		shl edx, cl	;Shift the type flags in dh to the right position
		
		and eax, edi	;Zero out the old type field of the debug register set, with the mask loaded before
		or eax, edx	;Write the new type attributes of the debug register set

		mov dr7, rax	;Write the new setup for all debug registers
		mov eax, r8d	;Load the handle for this specific breakpoint

		;Work is done return to the callee :)
		ret


;Will be called if an breakpoint triggers!
align 8
DebugException:
	push rbp
	mov rbp, rsp	;Set up an own stack for the handler function

	;Save rax, as an interrupt handler must not change any register values
	push rax

	;Load the information about the breakpoint which triggered
	mov rax, dr6
	
	;Zero out all information except the information about which breakpoint got triggered
	and eax, 0x0F
	
	;Load the number of the least significant bit into eax
	bsf eax, eax
	;If no bit is set in eax, end the function
	jz .func_end
	
	;Save rdx, as a interrupt handler must not change any register values
	push rdx
	xor edx, edx
	
	;If the debug breakpoint is an instruction debug breakpoint load edx with the value of the set resume flag
	;The flags on the stack will be loaded on leaving the interrupt handler, the resume flag will
	;ensure that the next instruction will not trigger an instruction breakpoint, therefore the programm
	;can continue the execution
	test byte[ rax + exception_settings.debug_0_type ], 3
	cmovz edx, dword[ exception_settings.eflags_resume_flag ]

	;If the breakpoint was not a instruction breakpoint it will or with 0 which does not change anything on the flags
	or qword[ rbp + 24 ], rdx
	
	pop rdx
	

	;Calculate the offset of which function to call
	shl eax, 3
	
	;Load the address of which breakpoint handler to invoke
	add rax, exception_settings.debug_0_handler

	;If no handler is installed for that exception skip that part
	cmp qword[ rax ], 0
	jz .func_end

	;Return address for the function
	push .func_end
	;Function address
	push qword[ rax ]
	;Restore rax, to ensure register consistensisty over function calls
	mov rax, qword[ rsp + 8 ]

	;"Return" calls the exception handler
	ret	
	
	;After the exception handler returns this will be executed
	.func_end:
		;Restore rax and the stack which was used before
		pop rax
		mov rsp, rbp
		pop rbp
		;Load back the right instruction pointer, code segment and flags
		iretq


exception_settings:
	.debug_0_handler dq 0
	.debug_1_handler dq 0
	.debug_2_handler dq 0
	.debug_3_handler dq 0
	.debug_0_type db 0
	.debug_1_type db 0
	.debug_2_type db 0
	.debug_3_type db 0
	.mask_0 dd 0xFFF0FFFF
	.mask_1 dd 0xFF0FFFFF
	.mask_2 dd 0xF0FFFFFF
	.mask_3 dd 0x0FFFFFFF
	.dbg_excp_handler dq 0
	.eflags_resume_flag dd EFLAGS_RESUME_FLAG

ImportAllMgrFunctions
