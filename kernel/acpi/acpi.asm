%include "acpi/acpi.inc"
INCLUDE "vga/vga_driver.inc"
INCLUDE "string/string.inc"
INCLUDE "memory/virtual_memory.inc"
%include "apic/apic.inc"


;InitialiseACPI searches for the ACPI tables and parses them to init the support for ACPI
;*
;*
DeclareFunction InitialiseACPI()

;Reserve some space for a string, it will print important informations about the whereabouts
	ReserveStackSpace CurrStr, KString1024
	UpdateStackPtr
	movzx edi, word[ 0x40E ]
	
	mov ecx, 0x1000		;Search in the first KB

	mov rax, RSDP_Signature	;Search for the RSDP Signature
	
	.SearchForRSDP:
		cmp qword[ edi ], rax	;If the signature is equal try the checksum
		jz .found

		add edi, 16		; The table must be at a 16-byte boundary
		sub ecx, 16		; 16 Bytes less to scan through
		jnz .SearchForRSDP

		cmp edi, 0x100000	; If the searching reaches 1 MB there will be no acpi table
		jz Errors.no_acpi

		mov edi, 0xE0000	; Else the first KB of the ebda was scanned through so scan the read only memory of the bios below 1 MB
		mov ecx, 0x20000	; from 1 MB - 0xE0000 = 0x20000
		jmp .SearchForRSDP


	.found:
		mov qword[ RootSystemDescPtr ], rdi	;okay the table signature was found
		
		cmp byte[ edi + RootSystemDescriptionPointer.revision ], 0	;Check if the version of the acpi table
		jz .acpi_1	;If the revision is zero, the table is ACPI version 1.0

	;Else the ACPI Version is 2.0 + and uses an other table format

	;Load the length in esi and validate the checksum
		mov esi, dword[ edi + RootSystemDescriptionPointer20.length ]
		call ValidateChecksum
		;if the carry flag is set print the error wrong checksum!
		jc Errors.wrong_checksum

		;Okay table is valid load the 64-bit address of the extended System Description Table
		mov rax, qword[ edi + RootSystemDescriptionPointer20.xsdt_addr ]
		;Save the address and specify the pointer size
		mov qword[ SystemDescriptorTable ], rax 
		mov qword[ ACPIPtrSize ], 8

		;Inform the user about the ACPI Tables
		secure_call DrawString( {0x0A, "Parsed ACPI Tables, 64-bit XSDT ACPI Rev 2+"})
		jmp .end	;Jump to the parsing part of the Initialistion

	.acpi_1:
		;The acpi version is 1.0, therefore the size of the table is the size of the RSDP structure
		mov esi, RootSystemDescriptionPointer_size
		
		;Validate the checksum for the table
		call ValidateChecksum
		;If the checksum is wrong print an error about invalid acpi tables to the user
		jc Errors.wrong_checksum

		;Load the 32-bit address of the system description table
		mov eax, dword[ edi + RootSystemDescriptionPointer.rsdt_addr ]
		;Save the address, and the pointer size of the acpi tables
		mov dword[ SystemDescriptorTable ], eax
		mov qword[ ACPIPtrSize ], 4

		;Inform the user about the acpi tables
		secure_call DrawString( {0x0A, "Parsed ACPI Tables, 32-bit RSDT ACPI Rev 1"})



	;.end is identical with .StartParsingDescTable , therefore end only identifies the end of the searching process
	.end:
	.StartParsingDescTable:
		;Identity-Map the address of the System Description Table, so that it can be accessed easily
		mov rbx, qword[ SystemDescriptorTable ]
		secure_call MapVirtToPhys( rbx, rbx, 0x1000, PAGE_READ_WRITE_EXECUTE|PAGE_CACHE_TYPE_WT)

		;Load the length of the entire table and calculate the length of the variable system description tables pointed by the RSDT
		mov r15d, dword[ rbx + ACPISystemDescriptorTableHeader.length ]
		sub r15d, ACPISystemDescriptorTableHeader_size

		;Calculate the start address of the variable System Description Tables
		add rbx, eXtendedSDT.ptr_start

		mov r14d, dword[ ACPIPtrSize ]	;Load the pointer size of the table into r14d

		;Traverse the ACPI Tables and try to parse as many as possible
		.TraverseList:
		;Check if it is a acpi 1.0 table or a acpi 2.0+ table
			cmp r14d, 4		;If the pointer size is 32-bit load just a 32-bit value
			cmovz esi, dword[ ebx ]	;Load 32-bit ptr
			cmovnz rsi, qword[ ebx ];Else load an 64-bit pointer

			push rsi		;Rsi will be trashed, therefore save it
			;Map the current table
			secure_call MapVirtToPhys( rsi, rsi, 0x1000, PAGE_READ|PAGE_CACHE_TYPE_WT|PAGE_FORCE_OVERWRITE)
			pop rsi					;Restore rsi
		
			cmp dword[ rsi ], MADT_Signature
			jnz .selectNextTable

			secure_call SupplyACPIApicTable( rsi )

			.selectNextTable:
				add rbx, r14		;Add the current pointer size to rbx to select the next entry
				sub r15, r14		;Subtract the number of bytes already processed
				ja .TraverseList	;If the number of bytes to process is bigger than zero, start processing the next pointer

			;All tables have been processed return!
EndFunction

Errors:
	.no_acpi:
		;First Clear the screen, then print the specific error message
		secure_call ClearScreen()
	
		secure_call DrawString({0x0A,CONSOLE_CHANGEFG(COLOR_BRIGHTRED),"No acpi available"})
		jmp $

	.wrong_checksum:
		;First Clear the screen, then print the specific error message
		secure_call ClearScreen()
		secure_call DrawString({0x0A, CONSOLE_CHANGEFG(COLOR_BRIGHTRED),"Wrong checksum in acpi table"})
		jmp $
	

;ValidateChecksum validates a checksum, with a variable length, from a given address
;edi = address, esi = length
ValidateChecksum:
	push rdi		;This function won't trash rdi, therefore save it
	mov al, byte[ edi ]	;Load the first byte into al
	
	add edi, 1		;Therefore the address must be increased and the length must be decreased
	sub esi, 1

	.Validate:
		add al, byte[ edi ]	;Add to al in succession the byte values pointed by rdi, until the length is zero
		add edi, 1
		sub esi, 1
		jnz .Validate
	
		;If al is zero the checksum is valid
		test al, al
		jnz .failed

		;Reload rdi, clear carry flag cause checksum is valid
		pop rdi
		clc
		ret

	.failed:
		;Checksum is invalid reload rdi, set carry flag
		pop rdi
		stc
		ret

ImportAllMgrFunctions

section .bss
RootSystemDescPtr resq 1
SystemDescriptorTable resq 1
ACPIPtrSize resq 1
