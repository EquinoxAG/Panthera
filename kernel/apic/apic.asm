%include "apic/apic.inc"
INCLUDE "vga/vga_driver.inc"
INCLUDE "acpi/acpi.inc"
INCLUDE "heap/heap.inc"
INCLUDE "memory/virtual_memory.inc"
INCLUDE "string/string.inc"
%include "cpu/cpu.inc"
%include "SD/system_desc.inc"


DeclareFunction SupplyACPIApicTable( addr )
	mov qword[ apic_settings.acpi_apic_table_addr], Arg_addr
EndFunction

RemapPICInterrupts:
	mov al, 0x11
	out PIC_MASTER_CMD, al		;Starts the initialisation sequence in cascade mode
	out PIC_SLAVE_CMD, al		;On master and on the slave

	mov al, 0x20
	out PIC_MASTER_DATA, al		;The new interrupt entrys assigned to the master start at 32
	add al, 8	
	out PIC_SLAVE_DATA, al		;The new interrupt entrys assigned to the slave start at 40

	mov al, 4			;Tell the master, that the slave is connected to IRQ2
	out PIC_MASTER_DATA, al
	mov al, 2
	out PIC_SLAVE_DATA, al		;Tell the slave, that it is a cascaded pic

	mov al, 1
	out PIC_MASTER_DATA, al		;Set the 8086 operating mode for slave and master
	out PIC_SLAVE_DATA, al

	;Initialisation sequence done, now mask all interrupts, because the IO-APIC will be used for interrupt routing
	mov al, 0xFF			;Mask all Interrupts on the PIC, because the the OS will use the IO-APIC
	out PIC_MASTER_DATA, al
	out PIC_SLAVE_DATA, al

	mov al, 0x70		;Select the ICMR Register 
	out 0x22, al

	mov al, 0x1		;Write 1 to the data register to enable symmetric IO-Mode
	out 0x23, al

	ret


DeclareFunction sendEOI()
	push rax
	mov eax, dword[ gs:CPUInfo.apic_addr ]
	mov dword[ eax + APICRegisters.eoi ], 0
	pop rax
EndFunction



align 8
;Handles a spurious interrupt if it fires, for a spurious interrupt no End of Interrupt is sended
SpuriousInterrupt:
	iretq	;So just return


DeclareFunction MapIOAPICEntryToIRQ( io_apic_entry, connected_isr )
	mov rcx, Arg_io_apic_entry
	;Translate IRQ into Table index
	shl ecx, 2
	mov ecx, dword[ InterruptRedirectionTable + ecx ]
	mov rdx, Arg_connected_isr

	mov rdi, qword[ apic_settings.io_apic_ptr ]

	.try_again:
		test rdi, rdi
		jz .end

		mov eax, dword[ rdi + IOAPICDesc.global_intr_source ]
	
		add eax, dword[ rdi + IOAPICDesc.num_remapping_intr ]

		cmp eax, ecx
		jns .map_entry

		mov edi, dword[ edi + IOAPICDesc.next_ptr ]
		jmp .try_again

	.map_entry:
		mov eax, dword[ rdi + IOAPICDesc.base ]
		
		shl ecx, 1
		add ecx, 0x10
		mov dword[ eax + IOAPIC_REGSEL ], ecx
		mov dword[ eax + IOAPIC_DATA ], edx

		add ecx, 1
		
		mov edx, dword[ gs:CPUInfo.apic_addr ]
		mov dword[ eax + IOAPIC_REGSEL ], ecx
		
		mov ecx, dword[ edx + APICRegisters.local_apic_id ]
		and ecx, 0xFF
		shl ecx, 24

		mov dword[ eax + IOAPIC_DATA ], ecx
	.end:
EndFunction

DeclareFunction InitialiseAPIC()	
	call RemapPICInterrupts		;First Remap the interrupts to 32-48 then mask all interrupts on the PIC
					;The remap is important if the spurious interrupt fires, it does not care about	masked interrupt lines

	;Is there an ACPI Apic table to parse?
	cmp qword[ apic_settings.acpi_apic_table_addr ], 0
	jz .CheckMultibootTable


	;Yes load the address of the acpi apic table
	mov rdi, qword[ apic_settings.acpi_apic_table_addr ]


	;Load the address of the local apic, and supply it to the settings
	mov eax, dword[ rdi + MultipleApicDescTable.local_apic_addr ]


	mov rbx, rax
	secure_call MapVirtToPhys( rax, rax, 0x1000, PAGE_READ_WRITE|PAGE_CACHE_TYPE_UC|PAGE_FORCE_OVERWRITE )
	mov rax, rbx

	mov dword[ eax + APICRegisters.spurious_interrupt_vector ], 0xF0|APIC_LOCAL_SPURIOUS_ENABLE	;Enable the APIC spurious vector is 0xF0
	
	mov dword[ eax + APICRegisters.divide_config ], 0xB
	mov dword[ eax + APICRegisters.lvt_timer ], 0x20	;Timer interrupt is interrupt 32

	secure_call SetIDTGate( 0xF0, SpuriousInterrupt, 3 )	;Set up a handler for the spurious interrupt vector

	mov ebx, InterruptRedirectionTable
	xor ecx, ecx
	.InitialiseTable:
		mov dword[ ebx ], ecx
		add ebx, 4
		add ecx, 1
		cmp ecx, 256
		jnz .InitialiseTable

	mov rbx, qword[ apic_settings.acpi_apic_table_addr ]	;Reload the address of the acpi apic table

	mov r15d, dword[ rbx + MultipleApicDescTable.length ]	;Load the length of the whole table
	sub r15d, MultipleApicDescTable_size			;Calculate the size of the variable size table 
	
	add rbx, MultipleApicDescTable_size	;Calculate the start of the variable size table

	.StartTraverse:
		cmp byte[ rbx + MADTEntryHeader.type ], MADT_IOApicEntryType
		jz .found_io_apic

		cmp byte[ rbx + MADTEntryHeader.type ], MADT_IntrSrcOverrideEntryType
		jz .found_intr_redirect
		
	.selectNext:
		movzx eax, byte[ rbx + MADTEntryHeader.length ]
		add ebx, eax
		sub r15d, eax
		ja .StartTraverse

		;IRQ 1 connected to interrupt 40
		secure_call MapIOAPICEntryToIRQ( 1, 40 )
		secure_call SetIDTGate( 40, .KeyboardTip, 3 )
		
		secure_call DrawString("Survived till end")
		jmp $
		sti
		jmp .function_end
	
	.found_intr_redirect:
		movzx eax, byte[ rbx + MADTEntryIntrSrcOverride.irq_source ]
		shl eax, 2		;Translate IRQ source into table index
		mov edx, dword[ rbx + MADTEntryIntrSrcOverride.global_system_intr ]
		mov dword[ eax + InterruptRedirectionTable ], edx	
		jmp .selectNext



	.found_io_apic:
		secure_call malloc( IOAPICDesc_size, "IO-APIC descriptor" )
		
		movzx r8d, byte[ rbx + MADTEntryIOAPIC.ioapic_id ]
		mov dword[ eax + IOAPICDesc.id ], r8d
		
		push rax
		mov eax, dword[ rbx + MADTEntryIOAPIC.ioapic_addr ]
		secure_call MapVirtToPhys( rax, rax, 0x1000,PAGE_READ_WRITE|PAGE_CACHE_TYPE_UC)
		pop rax

		mov edx, dword[ rbx + MADTEntryIOAPIC.ioapic_addr ]
		mov dword[ eax + IOAPICDesc.base ], edx
		
		mov dword[ edx + IOAPIC_REGSEL ], IOAPIC_REG_VER
	

		mov edx, dword[ edx + IOAPIC_DATA ]

		shr edx, 16
		and edx, 0xFF

		mov dword[ eax + IOAPICDesc.num_remapping_intr ], edx

		mov r8d, dword[ rbx + MADTEntryIOAPIC.global_system_intr_base ]
		mov dword[ eax + IOAPICDesc.global_intr_source ], r8d
		mov dword[ eax + IOAPICDesc.next_ptr ], 0

		mov edx, apic_settings.io_apic_ptr

		.SetNextIOAPIC:
			cmp dword[ edx ], 0
			jz .writeNewApic

			mov edx, dword[ edx ]
			add edx, IOAPICDesc.next_ptr
			jmp .SetNextIOAPIC



		
		.writeNewApic:
			mov dword[ edx ], eax

			mov eax, dword[ eax + IOAPICDesc.base ]
	
			jmp .selectNext
		
		
	align 8
	.KeyboardTip:
		push rax
		push rdx
	
		secure_call DrawString("Key pressed")

		in al, 0x60
		in al, 0x61
		or al, 0x80
		out 0x61, al
		and al, 0x7F
		out 0x61, al

		secure_call sendEOI()
		pop rdx
		pop rax
		iretq

	
	.CheckMultibootTable:
		;Is there a intel multiboot table?
		cmp qword[ apic_settings.intel_mbr_table_addr ], 0
		jz .not_enough_info

		jmp $

	.not_enough_info:
		;No, without a table it is very hard to intialise the APIC right, show an error
		secure_call ClearScreen()
		secure_call DrawString({CONSOLE_CHANGEFG(COLOR_BRIGHTRED),"Could not initialise APIC, without ACPI or Intel Multiboot Table!"})
		jmp $
	.function_end:

EndFunction


align 8
apic_settings:
	.acpi_apic_table_addr dq 0
	.intel_mbr_table_addr dq 0
	.processor_count dq 0
	.idt_length dw 256*16
	.idt_base dq 0
	.io_apic_ptr dq 0

ImportAllMgrFunctions

section .bss
InterruptRedirectionTable resd 256
